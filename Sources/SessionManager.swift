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
        case loginError
        case createUserError
    }
    
    typealias MessageHandler = (Any) -> ()
    
    // Variables
    var user: User?
    var messageHandler: MessageHandler?
    
    private let networkManager: NetworkManager
    private let networkMessages: NetworkMessages
    private var loginPromise: Promise<User>?
    private var createUserPromise: Promise<User>?
    private var sessionDown = false
    private var isLoggedIn = false
    private var sessionId: Int?
    
    // Methods
    init(networkManager: NetworkManager, networkMessages: NetworkMessages) {
        self.networkManager = networkManager
        self.networkMessages = networkMessages
        self.networkMessages.loginResponse.addHandler(target: self, handler: SessionManager.onLoginResponse)
        //self.networkEvents.logoutResponse.addHandler(target: self, handler: SessionManager.onLogoutResponse)
        self.networkMessages.createUserResponse.addHandler(target: self, handler: SessionManager.onCreateResponse)
        
        networkManager.connectionStateHandler = { [weak self] state in
            guard let self = self else { return }
            
            switch (self.isLoggedIn, state) {
            case (false, _         ): ()
            case (true , .none     ): self.sessionDown = true
            case (true , .connected): self.networkMessages.send(message: Login(userName: self.user.require().userName))
            }
        }
    }
    
    deinit {
        self.networkMessages.loginResponse.removeTarget(self)
        //self.networkEvents.logoutResponse.removeTarget(self)
        self.networkMessages.createUserResponse.removeTarget(self)
    }
    
    func createUserAndLogin(userName: String, color: [Double]) -> Future<User> {
        return Promise<User>(value: User(userName: userName, userId: nil, color: color))
            .chained { [weak self] user -> Future<Void> in
                guard let self = self else { throw SessionManagerError.createUserError }
                return self.networkMessages.send(message: CreateUser(user: user))
            }
            .chained { [weak self] () -> Future<User> in
                guard let self = self else { throw SessionManagerError.createUserError }
                let createUserPromise = Promise<User>()
                self.createUserPromise = createUserPromise
                return createUserPromise
            }
            .chained { [weak self] user -> Future<User> in
                guard let self = self else { throw SessionManagerError.createUserError }
                return self.login(userName: user.userName)
            }
    }
    
    func login(userName: String) -> Future<User> {
        return Promise<String>(value: userName)
            .chained { [weak self] in
                guard let self = self else { throw SessionManagerError.loginError }
                return self.networkMessages.send(message: Login(userName: $0))
            }
            .chained { [weak self] in
                guard let self = self else { throw SessionManagerError.loginError }
                self.loginPromise = Promise<User>()
                return self.loginPromise!
            }
    }
    
    func onCreateResponse(response: CreateUserResponse) {
        if let error = response.error {
            print("User creation failed: \(error)")
            createUserPromise?.reject(with: SessionManagerError.createUserError)
            return
        }
        
        guard let user = response.user else {
            print("User creation: Invalid response")
            createUserPromise?.reject(with: SessionManagerError.createUserError)
            return
        }
        
        createUserPromise?.resolve(with: user)
    }
    
    func onLoginResponse(response: LoginResponse) {
        isLoggedIn = false
        
        if let error = response.error {
            print("Login failed: \(error)")
            loginPromise?.reject(with: SessionManagerError.loginError)
            return
        }
        
        guard let user = response.user else {
            print("Login: Invalid response")
            loginPromise?.reject(with: SessionManagerError.loginError)
            return
        }
        
        self.user = user
        isLoggedIn = true
        loginPromise?.resolve(with: user)
    }
}
