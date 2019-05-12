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
import RxAppState
import PromiseKit

class NetworkManager {
    enum NetworkManagerError: Error {
        case noConnection
        case dataToStringFailed
    }

    public let onConnectionEstablished = PublishSubject<Void>()
    public let onConnectionClosed = PublishSubject<Void>()
    public let onMessage = PublishSubject<Data>()

    init() {
        assembleInteractions()
    }

    deinit {
        do {
            try self.group.syncShutdownGracefully()
        } catch {
            print("Failed to gracefully shut down: \(error)")
        }
    }

    public func send(_ codableMessage: Codable) -> Promise<Void> {
        return .init() { promise in
            guard let channel = self.channel else { throw NetworkManagerError.noConnection }

            let data = try JSONEncoder().encode(codableMessage)
            guard let str = String(data: data, encoding: .utf8) else { throw NetworkManagerError.dataToStringFailed }

            var buffer = channel.allocator.buffer(capacity: str.count)
            buffer.write(string: str)

            let writeFuture = channel.writeAndFlush(buffer, promise: nil)
            writeFuture.whenSuccess { promise.resolve() }
            writeFuture.whenFailure { promise.reject($0) }
        }
    }

    public var isConnected: Bool {
        return channel != nil
    }

    var shouldReconnect: Bool = true
    var channel: Channel?
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let disposeBag = DisposeBag()
}

extension NetworkManager {
    func assembleInteractions() {
        UIApplication.shared.rx.applicationDidEnterBackground
            .bind { [weak self] _ in
                self?.shouldReconnect = false
                _ = self?.channel?.close()
            }.disposed(by: disposeBag)

        UIApplication.shared.rx.applicationWillEnterForeground
            .bind { [weak self] _ in
                self?.shouldReconnect = true
                self?.run()
            }.disposed(by: disposeBag)
    }

    var bootstrap: ClientBootstrap {
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { [weak self] channel in
                let bridge = BridgeChannelHandler()

                bridge.onMessage
                    .bind { [weak self] in self?.onMessage.onNext($0) }
                    .disposed(by: bridge.disposeBag)

                let frameHandler = FrameChannelHandler()
                return channel.pipeline.addHandlers(frameHandler, bridge)
            }
    }

    func run() {
        print("Connecting to \(ApplicationSettings.host):\(ApplicationSettings.port)...")

        let connectFuture = bootstrap.connect(host: ApplicationSettings.host, port: ApplicationSettings.port)
        connectFuture.whenSuccess { [weak self] channel in
            guard let self = self else { return }

            print("Connected")

            self.onConnectionEstablished.onNext(())
            self.channel = channel

            channel.closeFuture.whenComplete { [weak self] _ in
                guard let self = self else { return }

                print("Disconnected")

                self.onConnectionClosed.onNext(())
                self.channel = nil

                guard self.shouldReconnect else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: self.run)
            }
        }

        connectFuture.whenFailure { [weak self] _ in
            guard let self = self else { return }
            guard self.shouldReconnect else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: self.run)
        }
    }
}
