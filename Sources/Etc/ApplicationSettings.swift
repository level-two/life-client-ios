//
//  ApplicationSettings.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 2/15/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class ApplicationSettings {
    enum SettingsKeys: String {
        case autologinEnabled
        case autologinUserName
    }
    
    static func getBool(for key: SettingsKeys) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    static func getString(for key: SettingsKeys) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }
    
    static func setBool(_ value: Bool, for key: SettingsKeys) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    static func setString(_ value: String, for key: SettingsKeys) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
