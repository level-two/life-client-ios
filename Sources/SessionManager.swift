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
    private let networkEvents: NetworkEvents
    private var loginPromise: Promise<User>?
    private var createUserPromise: Promise<User>?
    private var sessionDown = false
    private var isLoggedIn = false
    private var sessionId: Int?
    
    // Methods
    init(networkManager: NetworkManager, networkEvents: NetworkEvents) {
        self.networkManager = networkManager
        self.networkEvents = networkEvents
        self.networkEvents.loginResponse.addHandler(target: self, handler: SessionManager.onLoginResponse)
        //self.networkEvents.logoutResponse.addHandler(target: self, handler: SessionManager.onLogoutResponse)
        self.networkEvents.createUserResponse.addHandler(target: self, handler: SessionManager.onCreateResponse)
        
        networkManager.connectionStateHandler = { [weak self] state in
            guard let self = self else { return }
            
            switch (self.isLoggedIn, state) {
            case (false, _         ): ()
            case (true , .none     ): self.sessionDown = true
            case (true , .connected): self.networkManager.send(message: Login(userName: self.user.require().userName))
            }
        }
    }
    
    deinit {
        self.networkEvents.loginResponse.removeTarget(self)
        //self.networkEvents.logoutResponse.removeTarget(self)
        self.networkEvents.createUserResponse.removeTarget(self)
    }
    
    func createUserAndLogin(userName: String, color: [Double]) -> Future<User> {
        createUserPromise = Promise<User>()
        
        if networkManager.isConnected {
            networkManager.send(message: CreateUser(user: User(userName: userName, userId: nil, color: color)))
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
            networkManager.send(message: Login(userName: userName))
        }
        else {
            loginPromise?.reject(with: SessionManagerError.loginError("No connection to the server"))
        }
        
        return loginPromise!
    }
    
    func onLoginResponse(response: LoginResponse) {
        if let error = response.error {
            isLoggedIn = false
            loginPromise?.reject(with: SessionManagerError.loginError(error))
            loginPromise = nil
            return
        }
        
        guard let user = response.user else {
            isLoggedIn = false
            loginPromise?.reject(with: SessionManagerError.loginError("User is nil in the login response"))
            loginPromise = nil
            return
        }
        
        self.user = user
        isLoggedIn = true
        loginPromise?.resolve(with: user)
        loginPromise = nil
    }
    
    func onCreateResponse(response: CreateUserResponse) {
        if let error = response.error {
            createUserPromise?.reject(with: SessionManagerError.createUserError(error))
            createUserPromise = nil
            return
        }
        
        guard let user = response.user else {
            createUserPromise?.reject(with: SessionManagerError.createUserError("User is nil in the user create response"))
            createUserPromise = nil
            return
        }
        
        createUserPromise?.resolve(with: user)
        createUserPromise = nil
    }
}
