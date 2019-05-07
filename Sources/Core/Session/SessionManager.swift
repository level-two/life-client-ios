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
import RxSwift
import RxCocoa
import PromiseKit

class SessionManager {
    public enum SessionManagerError: Error {
        case operationTimeout
    }
    
    init(networkManager: NetworkManager, usersManager: UsersManager) {
        self.networkManager = networkManager
        self.usersManager = usersManager
    }

    var loggedInUserData: UserData?
    weak var networkManager: NetworkManager
    weak var usersManager: UsersManager
}

extension SessionManager {
    func sendLogin(for userName: String) -> Promise<Void> {
        return networkManager.send(.login(userName: userName))
    }
    
    func sendLogout(for userName: String) -> Promise<Void> {
        return networkManager.send(.logout(userName: userName))
    }
    
    func waitLoginResponse() -> Promise<UserData> {
        return .init() { [weak self] promise in
            let compositeDisposable = CompositeDisposable()
            
            self?.networkManager?.onMessage
                .bind { message in
                    guard case .loginResponseSuccess(let userData) = message else { return }
                    promise.resolve(with: userData)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
            
            self?.networkManager?.onMessage
                .bind { message in
                    guard case .loginResponseError(let error) = message else { return }
                    promise.reject(error)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
            
            let timeout = ApplicationSettings.operationTimeout
            
            Observable<Int>
                .timer(.init(timeout), period: nil, scheduler: MainScheduler.instance)
                .bind {
                    promise.reject(UsersManagerError.operationTimeout)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
        }
    }
    
    func waitLogoutResponse() -> Promise<UserData> {
        return .init() { [weak self] promise in
            let compositeDisposable = CompositeDisposable()
            
            self?.networkManager?.onMessage
                .bind { message in
                    guard case .logoutResponseSuccess(let userData) = message else { return }
                    promise.resolve(with: userData)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
            
            self?.networkManager?.onMessage
                .bind { message in
                    guard case .logoutResponseError(let error) = message else { return }
                    promise.reject(error)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
            
            let timeout = ApplicationSettings.operationTimeout
            
            Observable<Int>
                .timer(.init(timeout), period: nil, scheduler: MainScheduler.instance)
                .bind {
                    promise.reject(UsersManagerError.operationTimeout)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
        }
    }
}
