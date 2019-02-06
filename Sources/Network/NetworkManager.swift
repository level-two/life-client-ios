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


class NetworkManager {
    enum ConnectionState {
        case none
        case connected
    }
    
    typealias ConnectionStateHandler = (ConnectionState)->()
    
    let host = "192.168.100.64"
    let port = 1337
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var bootstrap: ClientBootstrap {
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { [weak self] channel in
                channel.pipeline.addHandlers([
                    FrameChannelHandler(),
                    MessageChannelHandler(),
                    BridgeChannelHandler { [weak self] message in self?.observable.notifyObservers(message) }
                    ], first: true)
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
    var appDelegateEvents: AppDelegateEvents!
    
    public var observable = Observable<Message>()
    
    // MARK: - Methods
    init(appDelegateEvents: AppDelegateEvents) {
        self.appDelegateEvents = appDelegateEvents
        appDelegateEvents.onApplicationDidEnterBackground.addHandler(target: self, handler: NetworkManager.onApplicationDidEnterBackground)
        appDelegateEvents.onApplicationWillEnterForeground.addHandler(target: self, handler: NetworkManager.onApplicationWillEnterForeground)
        connectToServer()
    }
    
    @discardableResult
    func send(message: Message) -> Future<Void> {
        print("Sending: \(message)")
        let promise = Promise<Void>()
        guard let writeFuture = channel?.writeAndFlush(NIOAny(message)) else {
            promise.reject(with: "No commection")
            return promise
        }
        writeFuture.whenSuccess {
            promise.resolve(with: ())
        }
        writeFuture.whenFailure { error in
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
                self?.channel = channel
                self?.isConnected = true
                return channel.closeFuture
            }.whenComplete { [weak self] in
                guard let self = self else { return }
                print("Not connected")
                self.channel = nil
                self.isConnected = false
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
