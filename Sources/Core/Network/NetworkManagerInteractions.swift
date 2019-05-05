//
//  NetworkManagerInteractions.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 5/5/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation


extension NetworkManager {
    public func assembleInteractions() {
        
    }
//    public func setupDependencies(appState: ApplicationStateObservable) {
//        appState.appStateObservable.addObserver(self) { [weak self] state in
//            guard let self = self else { return }
//            switch state {
//            case .didEnterBackground:
//                self.shouldReconnect = false
//                _ = self.channel?.close()
//            case .willEnterForeground:
//                self.shouldReconnect = true
//                self.run()
//            default: ()
//            }
//        }
//    }
    
//    func run() {
//        print("Connecting to \(host):\(port)...")
//        self.bootstrap
//            .connect(host: self.host, port: self.port)
//            .then { [weak self] channel -> EventLoopFuture<Void> in
//                print("Connected")
//                self?.channel = channel
//                self?.isConnected = true
//                return channel.closeFuture
//            }.whenComplete { [weak self] in
//                guard let self = self else { return }
//                print("Not connected")
//                self.channel = nil
//                self.isConnected = false
//                if self.shouldReconnect {
//                    sleep(1)
//                    self.run()
//                }
//        }
//    }
}
