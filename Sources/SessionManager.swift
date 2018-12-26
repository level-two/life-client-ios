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
import UIKit

class SessionManager {
    // Types
    enum LoginResult {
        case loggedIn(User)
        case error(String)
    }
    
    typealias MessageHandler = ([String:Any]) -> Void
    
    // Variables
    private let networkManager: NetworkManager
    private var messageHandler: MessageHandler?
    
    private var loginPromise: Promise<LoginResult>?
    private var user: User?
    private var isLoggedIn = false
    private var sessionId: Int?
    
    // Methods
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        
        networkManager.statusHandler = { [weak self] status in
            guard let self = self else { return }
            if status == .connected && self.isLoggedIn {
                self.networkManager.send(message: ["restoreSession": ["sessionId": self.sessionId]])
            }
        }
        
        networkManager.messageHandler = { [weak self] message in
            guard let self = self else { return }
            
            if let loginResponse = message["userLoggedIn"] as? [String:Any] {
                self.process(loginResponse: loginResponse)
            }
            if let restoreResponse = message["sessionRestored"] as? Bool {
                // Good =)
            }
            else if self.isLoggedIn {
                // pass message to the session delegates
            }
        }
    }
    
    func login(userName: String) -> Future<LoginResult> {
        loginPromise = Promise<LoginResult>()
        
        if networkManager.isConnected {
            networkManager.send(message: ["login": ["userName": userName]])
        }
        else {
            loginPromise?.resolve(with: .error("No connection to the server"))
        }
        
        return loginPromise!
    }
    
    func process(loginResponse: [String:Any]) {
        guard
            let userName = loginResponse["userName"] as? String,
            let userId = loginResponse["userId"] as? Int,
            let color = loginResponse["color"] as? [Double],
            color.count == 3,
            let newSessionId = loginResponse["sessionId"] as? Int
        else {
            loginPromise?.resolve(with: .error("Invalid server response"))
            loginPromise = nil
            return
        }
        user = User(userName: userName, userId: userId, color:color)
        sessionId = newSessionId
        loginPromise?.resolve(with: .loggedIn(user!))
        loginPromise = nil
    }
    
    /*
    func appEnterForeground() {
        connectToServer()
    }
    
    func appEnterBackground() {
        closeConnection()
    }
    
    func appTerminate() {
        try! self.group.syncShutdownGracefully()
    }
     */
}
