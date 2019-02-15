//
//  ApplicationSettings.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 2/15/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation

class ApplicationSettings {
    enum SettingsKeysForBool: String {
        case autologinEnabled
    }
    
    enum SettingsKeysForString: String {
        case autologinUserName
    }
    // TODO: Add subscription
    // TODO: Default values
    // TODO: Code with single enum?
    
    static func get(for key: SettingsKeysForBool) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    static func get(for key: SettingsKeysForString) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }
    
    static func set(_ value: Bool, for key: SettingsKeysForBool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    static func set(_ value: String, for key: SettingsKeysForString) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
