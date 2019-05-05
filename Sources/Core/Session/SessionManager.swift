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

protocol SessionProtocol {
    var loginStateObservable: Observable<Bool> { get }
    var user: User? { get }
    
    @discardableResult func createUserAndLogin(userName: String, uicolor: UIColor) -> Future<User>
    @discardableResult func createUser(userName: String, uicolor: UIColor) -> Future<User>
    @discardableResult func login(userName: String) -> Future<User>
    @discardableResult func logout(userName: String) -> Future<User>
}

class SessionManager: SessionProtocol {
    // Types
    enum SessionManagerError: Error {
        case loginError
        case logoutError
        case createUserError
    }
    
    // Variables
    var loginStateObservable = Observable<Bool>()
    var user: User?
    
    private var networkManager: NetworkManagerProtocol!
    private var loginPromise: Promise<User>?
    private var logoutPromise: Promise<User>?
    private var createUserPromise: Promise<User>?
    private var sessionId: Int?
    private var isLoggedIn = false { didSet { loginStateObservable.notifyObservers(self.isLoggedIn) } }
    
    func setupDependencies(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
        networkManager.onConnectedToServer.addObserver(self) { [weak self] isConnected in
            guard let self = self else { return }
            if self.user != nil && isConnected {
                self.login(userName: self.user!.userName)
            }
            else {
                self.isLoggedIn = false
            }
        }
        
        networkManager.onMessage.addObserver(self) { [weak self] message in
            guard let self = self else { return }
            switch message {
            case .loginResponse(let user, let error):      self.onLoginResponse (user: user, error: error)
            case .logoutResponse(let user, let error):     self.onLogoutResponse(user: user, error: error)
            case .createUserResponse(let user, let error): self.onCreateResponse(user: user, error: error)
            default:
                ()
            }
        }
    }
    
    @discardableResult
    func createUserAndLogin(userName: String, uicolor: UIColor) -> Future<User> {
        return createUser(userName:userName, uicolor: uicolor)
            .chained { [weak self] user in
                guard let self = self else { throw SessionManagerError.createUserError }
                return self.login(userName: user.userName)
        }
    }
    
    @discardableResult
    func createUser(userName: String, uicolor: UIColor) -> Future<User> {
        let user = User(userName: userName, userId: nil, color: uicolor.color)
        self.createUserPromise = Promise<User>()
        networkManager.send(message: .createUser(user: user)).observe { [weak self] result in
            guard let self = self else { return }
            if case .error(_) = result {
                self.createUserPromise?.reject(with: SessionManagerError.createUserError)
            }
        }
        return self.createUserPromise!
    }
    
    @discardableResult
    func login(userName: String) -> Future<User> {
        self.loginPromise = Promise<User>()
        networkManager.send(message: .login(userName: userName)).observe { [weak self] result in
            guard let self = self else { return }
            if case .error(_) = result {
                self.loginPromise?.reject(with: SessionManagerError.loginError)
            }
        }
        return self.loginPromise!
    }
    
    @discardableResult
    func logout(userName: String) -> Future<User> {
        self.logoutPromise = Promise<User>()
        networkManager.send(message: .logout(userName: userName)).observe { [weak self] result in
            guard let self = self else { return }
            if case .error(_) = result {
                self.logoutPromise?.reject(with: SessionManagerError.logoutError)
            }
        }
        return self.logoutPromise!
    }
    
    func onCreateResponse(user: User?, error: Error?) {
        if let _ = error {
            createUserPromise?.reject(with: SessionManagerError.createUserError)
            return
        }
        
        guard let user = user else {
            createUserPromise?.reject(with: SessionManagerError.createUserError)
            return
        }
        
        createUserPromise?.resolve(with: user)
    }
    
    func onLoginResponse(user: User?, error: Error?) {
        isLoggedIn = false
        self.user = nil
        
        if let _ = error {
            loginPromise?.reject(with: SessionManagerError.loginError)
            return
        }
        
        guard let user = user else {
            loginPromise?.reject(with: SessionManagerError.loginError)
            return
        }
        
        self.user = user
        isLoggedIn = true
        loginPromise?.resolve(with: user)
    }
    
    func onLogoutResponse(user: User?, error: Error?) {
        if let _ = error {
            logoutPromise?.reject(with: SessionManagerError.logoutError)
            return
        }
        
        guard let user = user else {
            logoutPromise?.reject(with: SessionManagerError.logoutError)
            return
        }
        
        self.user = nil
        isLoggedIn = false
        logoutPromise?.resolve(with: user)
    }
}
