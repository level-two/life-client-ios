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
        case logoutError
        case createUserError
    }
    
    typealias MessageHandler = (Any) -> ()
    
    // Variables
    var user: User?
    var messageHandler: MessageHandler?
    
    private let networkManager: NetworkManager
    private let networkMessages: NetworkMessages
    private var loginPromise: Promise<User>?
    private var logoutPromise: Promise<User>?
    private var createUserPromise: Promise<User>?
    private var isLoggedIn = false {
        didSet {
            loginStateEvent.raise(with: isLoggedIn)
        }
    }
    private var sessionId: Int?
    let loginStateEvent = Event1<Bool>()
    
    // Methods
    init(networkManager: NetworkManager, networkMessages: NetworkMessages) {
        self.networkManager = networkManager
        self.networkMessages = networkMessages
        self.networkMessages.loginResponse.addHandler(target: self, handler: SessionManager.onLoginResponse)
        self.networkMessages.logoutResponse.addHandler(target: self, handler: SessionManager.onLogoutResponse)
        self.networkMessages.createUserResponse.addHandler(target: self, handler: SessionManager.onCreateResponse)
        
        networkManager.connectionStateHandler = { [weak self] state in
            guard let self = self else { return }
            if self.user != nil && state == .connected {
                _ = self.login(userName: self.user!.userName)
            }
            else {
                self.isLoggedIn = false
            }
        }
    }
    
    deinit {
        self.networkMessages.loginResponse.removeTarget(self)
        self.networkMessages.logoutResponse.removeTarget(self)
        self.networkMessages.createUserResponse.removeTarget(self)
    }
    
    func createUserAndLogin(userName: String, color: [Double]) -> Future<User> {
        return createUser(userName:userName, color: color)
            .chained { [weak self] user in
                guard let self = self else { throw SessionManagerError.createUserError }
                return self.login(userName: user.userName)
        }
    }
    
    func createUser(userName: String, color: [Double]) -> Future<User> {
        let user = User(userName: userName, userId: nil, color: color)
        self.createUserPromise = Promise<User>()
        networkMessages.send(message: CreateUser(user: user)).observe { [weak self] result in
            guard let self = self else { return }
            if case .error(_) = result {
                self.createUserPromise?.reject(with: SessionManagerError.createUserError)
            }
        }
        return self.createUserPromise!
    }
    
    func login(userName: String) -> Future<User> {
        self.loginPromise = Promise<User>()
        networkMessages.send(message: Login(userName: userName)).observe { [weak self] result in
            guard let self = self else { return }
            if case .error(_) = result {
                self.loginPromise?.reject(with: SessionManagerError.loginError)
            }
        }
        return self.loginPromise!
    }
    
    func logout(userName: String) -> Future<User> {
        self.logoutPromise = Promise<User>()
        networkMessages.send(message: Logout(userName: userName)).observe { [weak self] result in
            guard let self = self else { return }
            if case .error(_) = result {
                self.logoutPromise?.reject(with: SessionManagerError.logoutError)
            }
        }
        return self.logoutPromise!
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
        self.user = nil
        
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
    
    func onLogoutResponse(response: LogoutResponse) {
        if let error = response.error {
            print("Logout failed: \(error)")
            logoutPromise?.reject(with: SessionManagerError.logoutError)
            return
        }
        
        guard let user = response.user else {
            print("Logout: Invalid response")
            logoutPromise?.reject(with: SessionManagerError.logoutError)
            return
        }
        
        self.user = nil
        isLoggedIn = false
        logoutPromise?.resolve(with: user)
    }
}
