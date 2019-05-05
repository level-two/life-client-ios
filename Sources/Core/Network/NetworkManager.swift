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

/*
protocol NetworkManagerInterface {
    var onConnectionEstablished: PublishSubject<ConnectionId> { get }
    var onConnectionClosed: PublishSubject<ConnectionId> { get }
    var onMessage: PublishSubject<(ConnectionId, Data)> { get }
    
    @discardableResult func send(message: Message) -> Future<Void>
}
*/

class NetworkManager {
    public let onConnectionEstablished = PublishSubject<ConnectionId>()
    public let onConnectionClosed = PublishSubject<ConnectionId>()
    public let onMessage = PublishSubject<(ConnectionId, Data)>()
    
    
    @discardableResult
    public func send(message: Message) -> Future<Void> {
        guard let writeFuture = channel?.writeAndFlush(NIOAny(message)) else {
            return Promise<Void>(error: "No connection")
        }
        
        let promise = Promise<Void>()
        writeFuture.whenSuccess { promise.resolve(with: ()) }
        writeFuture.whenFailure { error in promise.reject(with: error) }
        return promise
    }
    
    fileprivate let host = ""
    
    fileprivate let port = 1337
    
    fileprivate let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    fileprivate var channel: Channel? = nil
    
    fileprivate var shouldReconnect: Bool = true
//    fileprivate var isConnected = false { didSet { onConnectedToServer.notifyObservers(self.isConnected) } }
}


extension NetworkManager {
    func makeBootstrap(with channelInitializer: @escaping (Channel)->EventLoopFuture<Void>) -> ClientBootstrap {
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer(channelInitializer)
    }
    
}
