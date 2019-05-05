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
import RxSwift
import PromiseKit

class NetworkManager {
    enum NetworkManagerError: Error {
        case noConnection
        case dataToStringFailed
    }
    
    public let onConnectionEstablished = PublishSubject<ConnectionId>()
    public let onConnectionClosed = PublishSubject<ConnectionId>()
    public let onMessage = PublishSubject<(ConnectionId, Data)>()
    
    @discardableResult
    public func send(data: Data) -> Future<Void> {
        return .init() { [weak self] promise in
            guard let channel = self?.channel else { throw NetworkManagerError.noConnection }
            guard let str = String(data: data, encoding: .utf8) else { throw NetworkManagerError.dataToStringFailed }
            
            var buffer = channel.allocator.buffer(capacity: str.count)
            buffer.write(string: str)
            
            let writeFuture = channel.writeAndFlush(buffer, promise: nil)
            writeFuture.whenSuccess { promise.resolve() }
            writeFuture.whenFailure { promise.reject($0) }
        }
    }
    
    deinit {
        do {
            try self.group.syncShutdownGracefully()
        } catch {
            print("Failed to gracefully shut down: \(error)")
        }
    }
    
    fileprivate let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    fileprivate var channel: Channel? = nil
    
    fileprivate var shouldReconnect: Bool = true
    fileprivate var isConnected = false {
        didSet { onConnectedToServer.notifyObservers(self.isConnected)
        }
    }
}


extension NetworkManager {
    var bootstrap: ClientBootstrap {
        return .init(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { [weak self] channel in
                guard let self = self else { return nil }
                
                let bridge = BridgeChannelHandler()
                bridge.onMessage
                    .bind(to: self.onMessage)
                    .disposed(by: bridge.disposeBag)
                
                return channel.pipeline.addHandlers(FrameChannelHandler(), bridge, first: true)
            }
    }
    
    func run() {
        print("Connecting to \(ApplicationSettings.host):\(ApplicationSettings.port)...")
        
        bootstrap.connect(host: ApplicationSettings.host, port: ApplicationSettings.port)
            .then { [weak self] channel -> EventLoopFuture<Void> in
                print("Connected")
                self?.onConnectionEstablished.onNext(())
                self?.channel = channel
                return channel.closeFuture
            }.whenComplete { [weak self] in
                guard let self = self else { return }

                print("Disconnected")
                self.onConnectionClosed.onNext(())
                self.channel = nil
                if self.shouldReconnect {
                    sleep(1)
                    self.run()
                }
            }
    }
}
