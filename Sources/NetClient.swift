// -----------------------------------------------------------------------------
//    Copyright (C) 2018 Yauheni Lychkouski.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------

import Foundation
import NIO
import NIOFoundationCompat

final class JsonDes: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias MessageHandler = ([String:Any]) -> Void
    
    private let messageHandler: MessageHandler
    
    init(messageHandler: @escaping MessageHandler) {
        self.messageHandler = messageHandler
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuf = self.unwrapInboundIn(data)
        let readData = byteBuf.getData(at:byteBuf.readerIndex, length:byteBuf.readableBytes)!
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: readData, options: []) else { return }
        guard let message = jsonObject as? [String:Any] else { return }
        
        print(message)
        self.messageHandler(message)
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        ctx.close(promise: nil)
    }
}


final class JsonSer: ChannelOutboundHandler {
    public typealias OutboundIn = [String:Any]
    public typealias OutboundOut = ByteBuffer
    
    public func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let message = self.unwrapOutboundIn(data)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        var buffer = ctx.channel.allocator.buffer(capacity: jsonString.count)
        buffer.write(string: jsonString)
        //ctx.channel.writeAndFlush(buffer, promise: nil)
        ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: promise)
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        ctx.close(promise: nil)
    }
}

class NetClient {
    static let shared = NetClient()
    
    let onConnectionEstablishedEvent = Event0()
    let onConnectionClosedEvent = Event0()
    let onConnectionFailedEvent = Event0()
    let onConnectionReceivedMessageEvent = Event1<[String:Any]>()
    
    // Connection
    let port = 1337
    //let host = "::1"
    let host = "192.168.100.28"
    let group: MultiThreadedEventLoopGroup
    var channel: Channel? = nil
    
    var bootstrap: ClientBootstrap {
        let messageHandler: JsonDes.MessageHandler = { [weak self] message in
            self?.onConnectionReceivedMessageEvent.raise(with: message)
        }
        
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.add(handler:JsonSer()).then { _ in
                    channel.pipeline.add(handler:JsonDes(messageHandler: messageHandler))
                }
            }
    }
    
    fileprivate init() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    func appEnterForeground() {
        connectToServer()
    }
    
    func appEnterBackground() {
        closeConnection()
    }
    
    func appTerminate() {
        try! self.group.syncShutdownGracefully()
    }
    
    func send(message: [String:Any]) {
        self.channel?.write(message, promise:nil)
    }
    
    fileprivate func connectToServer() {
        let channelFuture = self.bootstrap.connect(host: self.host, port: self.port)
            
        channelFuture.whenSuccess { [weak self] channel in
            print("Connected")
            self?.channel = channel
            self?.onConnectionEstablishedEvent.raise()
            
            self?.channel?.closeFuture.whenSuccess { [weak self] in
                print("Connection closed")
                self?.onConnectionClosedEvent.raise()
                self?.channel = nil
            }
            
            self?.channel?.closeFuture.whenFailure { [weak self] error in
                print("Disconnected with error: \(error)")
                self?.onConnectionFailedEvent.raise()
                self?.channel = nil
                sleep(1)
                self?.connectToServer()
            }
        }
        
        channelFuture.whenFailure { [weak self] error in
            print("Connection attempt failed: \(error)")
            self?.onConnectionFailedEvent.raise()
            sleep(1)
            self?.connectToServer()
        }
    }
    
    fileprivate func closeConnection() {
        _ = self.channel?.close()
    }
}
