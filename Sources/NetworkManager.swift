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

final class ChannelInboundBridge: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias MessageHandler = (String) -> Void

    private let messageHandler: MessageHandler
    private var receivedMessage = ""
    
    init(messageHandler: @escaping MessageHandler) {
        self.messageHandler = messageHandler
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuf = self.unwrapInboundIn(data)
        guard let string = byteBuf.getString(at:byteBuf.readerIndex, length:byteBuf.readableBytes) else { return }
        
        receivedMessage += string
        while let range = receivedMessage.rangeOfCharacter(from: .newlines) {
            let message = receivedMessage[..<range.lowerBound]
            self.messageHandler(String(message))
            receivedMessage.removeSubrange(..<range.upperBound)
        }
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("JsonDesChannelInboundHandler error: ", error)
        ctx.close(promise: nil)
    }
}


class NetworkManager {
    // MARK: - Types
    enum ConnectionState {
        case none
        case connected
    }
    
    enum NetworkManagerError: Error {
        case error(String)
    }
    
    typealias ConnectionStateHandler = (ConnectionState)->()
    typealias MessageHandler = (String)->()
    
    // MARK: - Variables
    let host = "localhost"
    let port = 1337
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var bootstrap: ClientBootstrap {
        let inboundBridge = ChannelInboundBridge { [weak self] string in
            self?.messageHandler?(string)
        }
        
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in channel.pipeline.add(handler: inboundBridge)
        }
    }
    var channel: Channel? = nil
    var shouldReconnect: Bool = true
    var connectionStateHandler: ConnectionStateHandler?
    var isConnected = false {
        didSet {
            connectionStateHandler?(isConnected ? .connected : .none)
        }
    }
    var messageHandler: MessageHandler?
    var appDelegateEvents: AppDelegateEvents!
    
    // MARK: - Methods
    init(appDelegateEvents: AppDelegateEvents) {
        self.appDelegateEvents = appDelegateEvents
        appDelegateEvents.onApplicationDidEnterBackground.addHandler(target: self, handler: NetworkManager.onApplicationDidEnterBackground)
        appDelegateEvents.onApplicationWillEnterForeground.addHandler(target: self, handler: NetworkManager.onApplicationWillEnterForeground)
        connectToServer()
    }
    
    @discardableResult
    func send(string: String) -> Future<Void> {
        let promise = Promise<Void>()
        
        print("Sending: \(string)")
        
        guard let ch = self.channel else {
            promise.reject(with: NetworkManagerError.error("No Connection"))
            return promise
        }
        
        var buffer = ch.allocator.buffer(capacity: string.count)
        buffer.write(string: string)
        
        let writePromise = ch.writeAndFlush(buffer)
        writePromise.whenSuccess {
            print("Message sent")
            promise.resolve(with: ())
        }
        writePromise.whenFailure { error in
            print("Failed to send message: \(error)")
            promise.reject(with: error)
        }
        
        return promise
    }
    
    private func connectToServer() {
        print("Connecting to \(host):\(port)...")
        self.bootstrap
            .connect(host: self.host, port: self.port)
            .then { [weak self] channel -> EventLoopFuture<Void> in
                print("Connected")
                self?.isConnected = true
                self?.channel = channel
                return channel.closeFuture
            }.whenComplete { [weak self] in
                guard let self = self else { return }
                print("Not connected")
                self.isConnected = false
                self.channel = nil
                if self.shouldReconnect {
                    sleep(1)
                    self.connectToServer()
                }
            }
    }
    
    func onApplicationDidEnterBackground() {
        shouldReconnect = false
        _ = self.channel?.close()
    }
    
    func onApplicationWillEnterForeground() {
        shouldReconnect = true
        connectToServer()
    }
}
