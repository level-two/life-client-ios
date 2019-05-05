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

protocol NetworkManagerProtocol {
    var onMessage           : Observable<Message> { get }
    var onConnectedToServer : Observable<Bool>    { get }
    
    @discardableResult func send(message: Message) -> Future<Void>
}

class NetworkManager: NetworkManagerProtocol {
    let onMessage           = Observable<Message>()
    let onConnectedToServer = Observable<Bool>()
    
    let host = "127.0.0.1"
    let port = 1337
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var bootstrap: ClientBootstrap {
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { [weak self] channel in
                channel.pipeline.addHandlers([
                    FrameChannelHandler(),
                    MessageChannelHandler(),
                    BridgeChannelHandler { [weak self] message in self?.onMessage.notifyObservers(message) }
                    ], first: true)
            }
    }
    
    var channel: Channel? = nil
    var shouldReconnect: Bool = true
    var isConnected = false { didSet { onConnectedToServer.notifyObservers(self.isConnected) } }
    
    func setupDependencies(appState: ApplicationStateObservable) {
        appState.appStateObservable.addObserver(self) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .didEnterBackground:
                self.shouldReconnect = false
                _ = self.channel?.close()
            case .willEnterForeground:
                self.shouldReconnect = true
                self.run()
            default: ()
            }
        }
    }
    
    @discardableResult
    func send(message: Message) -> Future<Void> {
        guard let writeFuture = channel?.writeAndFlush(NIOAny(message)) else {
            return Promise<Void>(error: "No connection")
        }
        
        let promise = Promise<Void>()
        writeFuture.whenSuccess { promise.resolve(with: ()) }
        writeFuture.whenFailure { error in promise.reject(with: error) }
        return promise
    }
    
    func run() {
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
                    self.run()
                }
            }
    }
}
