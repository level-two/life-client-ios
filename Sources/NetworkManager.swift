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

final class JsonDesChannelInboundHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias MessageHandler = (Any) -> Void
    
    private let messageHandler: MessageHandler
    
    init(messageHandler: @escaping MessageHandler) {
        self.messageHandler = messageHandler
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuf = self.unwrapInboundIn(data)
        let readData = byteBuf.getData(at:byteBuf.readerIndex, length:byteBuf.readableBytes)!
        
        guard let message = try? JSONSerialization.jsonObject(with: readData, options: []) else { return }
        self.messageHandler(message)
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("JsonDesChannelInboundHandler error: ", error)
        ctx.close(promise: nil)
    }
}


final class JsonSerChannelOutboundHandler: ChannelOutboundHandler {
    public typealias OutboundIn = Any
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
        print("JsonSerChannelOutboundHandler error: ", error)
        ctx.close(promise: nil)
    }
}

class NetworkManager {
    // MARK: - Types
    enum Status {
        case none
        case connected
    }
    
    typealias StatusHandler = (Status)->()
    typealias MessageHandler = (Any)->()
    
    // MARK: - Variables
    let host = "localhost"
    //let host = "192.168.100.28"
    let port = 1337
    
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var bootstrap: ClientBootstrap {
        let jsonInboundHandler = JsonDesChannelInboundHandler { [weak self] message in
            print("Received message: \(message)")
            self?.messageHandler?(message)
        }
        
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.add(handler: jsonInboundHandler).then { _ in
                    channel.pipeline.add(handler: JsonSerChannelOutboundHandler())
                }
        }
    }
    var channel: Channel? = nil
    
    var statusHandler: StatusHandler?
    var messageHandler: MessageHandler?
    
    var isConnected = false {
        didSet {
            statusHandler?(isConnected ? .connected : .none)
        }
    }
    
    // MARK: - Methods
    init() {
        connectToServer()
    }
    
    func send(message: Any) {
        self.channel?.write(message, promise: nil)
    }
    
    private func connectToServer() {
        print("Connecting to \(host):\(port)...")
        let channelFuture = self.bootstrap.connect(host: self.host, port: self.port)
        
        channelFuture.whenFailure { [weak self] error in
            print("Connection failed: \(error)")
            self?.isConnected = false
        }
        
        channelFuture.whenSuccess { [weak self] channel in
            print("Connected")
            self?.channel = channel
            self?.isConnected = true
            
            self?.channel?.closeFuture.whenSuccess { [weak self] in
                print("Connection closed")
                self?.isConnected = false
                self?.channel = nil
                sleep(1)
                self?.connectToServer()
            }
            
            self?.channel?.closeFuture.whenFailure { [weak self] error in
                print("Disconnected with error: \(error)")
                self?.isConnected = false
                self?.channel = nil
                sleep(1)
                self?.connectToServer()
            }
        }
    }
    
    private func closeConnection() {
        _ = self.channel?.close()
    }
}
