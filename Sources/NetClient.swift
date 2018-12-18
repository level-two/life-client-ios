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
import Reachability
import NIO
import NIOFoundationCompat

final class JsonDes: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias ChannelEventHandler = (ChannelEvent, [String:Any]?) -> Void
    
    enum ChannelEvent {
        case channelOpened
        case channelClosed
        case channelRead
    }
    
    private let channelEventHandler: ChannelEventHandler
    
    init(channelEventHandler: @escaping ChannelEventHandler) {
        self.channelEventHandler = channelEventHandler
    }
    
    public func channelActive(ctx: ChannelHandlerContext) {
        self.channelEventHandler(.channelOpened, nil)
    }
    
    public func channelInactive(ctx: ChannelHandlerContext) {
        self.channelEventHandler(.channelClosed, nil)
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuf = self.unwrapInboundIn(data)
        let readData = byteBuf.getData(at:byteBuf.readerIndex, length:byteBuf.readableBytes)!
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: readData, options: []) else { return }
        guard let message = jsonObject as? [String:Any] else { return }
        
        print(message)
        self.channelEventHandler(.channelRead, message)
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


protocol NetClientDelegate {
    func onConnectionEstablished()
    func onConnectionClosed()
    func onConnection(received message:[String:Any])
    func onNetReachable()
    func onNetNotReachable()
}


class NetClient {
    static let shared = NetClient()
    
    var delegate = MulticastDelegate<NetClientDelegate>()
    
    // Reachability
    var reachabilityStatus: Reachability.Connection = .none
    let reachability = Reachability()
    var isNetworkAvailable : Bool {
        return reachabilityStatus != .none
    }
    
    // Connection
    let port = 1337
    let host = "::1"
    let group: MultiThreadedEventLoopGroup
    var channel: Channel? = nil
    
    var bootstrap: ClientBootstrap {
        let channelEventHandler: JsonDes.ChannelEventHandler = { [weak self] channelEventType, message in
            switch channelEventType {
            case .channelOpened:
                self?.delegate.invoke { $0.onConnectionEstablished() }
            case .channelClosed:
                self?.delegate.invoke { $0.onConnectionClosed() }
            case .channelRead:
                guard let message = message else { return }
                self?.delegate.invoke { $0.onConnection(received: message) }
            }
        }
        
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.add(handler:JsonSer()).then { _ in
                    channel.pipeline.add(handler:
                        JsonDes(channelEventHandler:channelEventHandler))
                }
        }
    }
    
    fileprivate init() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        reachability?.whenReachable = { [weak self] _ in
            self?.delegate.invoke { $0.onNetReachable() }
        }
        
        reachability?.whenUnreachable = { [weak self] _ in
            self?.delegate.invoke { $0.onNetNotReachable() }
        }
    }
    
    deinit {
        // Close all open sockets...
        try! self.group.syncShutdownGracefully()
    }
    
    // Reachability
    func startNetReachabilityMonitoring() {
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func stopNetReachabilityMonitoring() {
        reachability?.stopNotifier()
    }
    
    // Client
    func connectToServer() throws {
        self.bootstrap
            .connect(host: self.host, port: self.port)
            .whenSuccess { [weak self] channel in
                self?.channel = channel
                self?.channel?.closeFuture.whenComplete { [weak self] in
                    self?.delegate.invoke { $0.onConnectionClosed() }
                    self?.channel = nil
                }
            }
    }
    
    public func send(message: [String:Any]) {
        self.channel?.write(message, promise:nil)
    }
}
