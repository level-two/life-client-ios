// -----------------------------------------------------------------------------
//    Copyright (C) 2019 Yauheni Lychkouski.
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
    
    static public var operationTimeout: Double {
        return 5
    }
}
