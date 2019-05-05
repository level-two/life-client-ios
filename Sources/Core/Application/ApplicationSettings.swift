//
//  ApplicationSettings.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 2/15/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class ApplicationSettings {
    static public var autologinEnabled: Bool {
        get { return UserDefaults.standard.bool(forKey: #function) }
        set { UserDefaults.standard.set(newValue, forKey: #function) }
    }
    
    static public var autologinUserName: String {
        get { return UserDefaults.standard.string(forKey: #function) }
        set { UserDefaults.standard.set(newValue, forKey: #function) }
    }
    
    static public var host: String {
        if let host = ProcessInfo.processInfo.environment["host"] as? String {
            return host
        }
        return "gameoflife.ddns.net"
    }
    
    static public var port: Int {
        if let port = ProcessInfo.processInfo.environment["port"] as? Int {
            return port
        }
        return 1337
    }
}
