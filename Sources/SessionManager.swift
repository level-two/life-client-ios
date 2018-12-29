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
        case createUserError(String)
    }
    
    typealias MessageHandler = (Any) -> ()
    
    // Variables
    var user: User?
    var messageHandler: MessageHandler?
    
    private let networkManager: NetworkManager
    private var loginPromise: Promise<User>?
    private var createUserPromise: Promise<User>?
    private var sessionDown = false
    private var isLoggedIn = false
    private var sessionId: Int?
    
    // Methods
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        
        networkManager.statusHandler = { [weak self] status in
            guard let self = self else { return }
            
            if self.isLoggedIn == false {
                // do nothing
            }
            else if status == .none {
                self.sessionDown = true
            }
            else if status == .connected {
                self.networkManager.send(message: ["restoreSession": ["sessionId": self.sessionId]])
            }
        }
        
        networkManager.messageHandler = { [weak self] message in
            guard let self = self else { return }
            let isProcessed = self.tryProcessSessionMessage(message: message)
            if !isProcessed && self.isLoggedIn {
                // pass message to the session delegates
                self.messageHandler?(message)
            }
        }
    }
    
    func createUserAndLogin(userName: String, color: [Double]) -> Future<User> {
        createUserPromise = Promise<User>()
        
        if networkManager.isConnected {
            networkManager.send(message: ["create": ["userName": userName, "color":color]])
        }
        else {
            createUserPromise!.reject(with: SessionManagerError.loginError("No connection to the server"))
        }
        
        let createUserAndLoginPromise = createUserPromise!.chained { [unowned self] user -> Future<User> in
            return self.login(userName: user.userName)
        }
        
        return createUserAndLoginPromise
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
    
    @discardableResult func sendSessionMessage(_ message: Any) -> Bool {
        if isLoggedIn && !sessionDown {
            networkManager.send(message: message)
            return true
        }
        return false
    }
    
    private func tryProcessSessionMessage(message rawMessage: Any) -> Bool {
        guard let message = rawMessage as? [String:Any] else {
            return false
        }
        var isProcessed = true
        if let resp = message["userLoggedIn"] {
            process(loginResponse: resp)
        }
        else if let resp = message["userLoginError"] {
            process(loginErrorResponse: resp)
        }
        else if let resp = message["userCreated"] {
            process(createUserResponse: resp)
        }
        else if let resp = message["userCreationError"] {
            process(createUserErrorResponse: resp)
        }
        else if let _ = message["sessionRestored"] {
            // Good =)
        }
        else {
            isProcessed = false
        }
        return isProcessed
    }
    
    private func process(loginResponse response: Any) {
        guard
            let data = response as? [String:Any],
            let newSessionId = data["sessionId"] as? Int,
            let user = User(withDictionary: response)
        else {
            loginPromise?.reject(with: SessionManagerError.loginError("Invalid server response"))
            loginPromise = nil
            return
        }
        
        self.user = user
        sessionId = newSessionId
        isLoggedIn = true
        loginPromise?.resolve(with: user)
        loginPromise = nil
    }
    
    private func process(loginErrorResponse response: Any) {
        guard let message = response as? String else {
            print("Invalid response. Expected String")
            return
        }
        isLoggedIn = false
        loginPromise?.reject(with: SessionManagerError.loginError(message))
        loginPromise = nil
    }
    
    private func process(createUserResponse response: Any) {
        guard let user = User(withDictionary: response) else {
            createUserPromise?.reject(with: SessionManagerError.createUserError("Invalid server response"))
            createUserPromise = nil
            return
        }
        createUserPromise?.resolve(with: user)
        createUserPromise = nil
    }
    
    private func process(createUserErrorResponse response: Any) {
        guard let message = response as? String else {
            print("Invalid response. Expected String")
            return
        }
        createUserPromise?.reject(with: SessionManagerError.createUserError(message))
        createUserPromise = nil
    }
    
    private func process(sessionResponse response: Any) {
        guard let isRestored = response as? Bool else {
            print("Invalid response. Expected Bool")
            return
        }
        sessionDown = !isRestored
    }
    
    private func process(sessionErrorResponse response: Any) {
        guard let message = response as? String else {
            print("Invalid response. Expected String")
            return
        }
        print("Failed to restore session: \(message)")
    }
}
