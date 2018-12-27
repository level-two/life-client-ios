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
    enum SessionManagerError: Error {
        case loginError(String)
    }
    
    typealias MessageHandler = ([String:Any]) -> Void
    
    // Variables
    private let networkManager: NetworkManager
    private var messageHandler: MessageHandler?
    
    private var loginPromise: Promise<User>?
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
            
            if let resp = message["userLoggedIn"] as? [String:Any] {
                self.process(loginResponse: resp)
            }
            else if let resp = message["userLoginError"] as? String {
                self.process(loginErrorResponse: resp)
            }
            else if let _ = message["sessionRestored"] as? Bool {
                // Good =)
            }
            else if self.isLoggedIn {
                // pass message to the session delegates
                self.messageHandler?(message)
            }
        }
    }
    
    func login(userName: String) -> Future<User> {
        loginPromise = Promise<User>()
        
        if networkManager.isConnected {
            networkManager.send(message: ["login": ["userName": userName]])
        }
        else {
            loginPromise?.reject(with: SessionManagerError.loginError("No connection to the server"))
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
            loginPromise?.reject(with: SessionManagerError.loginError("Invalid server response"))
            loginPromise = nil
            return
        }
        
        sessionId = newSessionId
        user = User(userName: userName, userId: userId, color:color)
        loginPromise?.resolve(with: user!)
        loginPromise = nil
    }
    
    func process(loginErrorResponse: String) {
        loginPromise?.reject(with: SessionManagerError.loginError(loginErrorResponse))
        loginPromise = nil
    }
}
