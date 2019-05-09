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

    init(_ networkManager: NetworkManager, _ usersManager: UsersManager) {
        self.networkManager = networkManager
        self.usersManager = usersManager

        assembleInteractions()
    }

    var loggedInUserData: UserData?
    let networkManager: NetworkManager
    let usersManager: UsersManager
}

extension SessionManager {
    @discardableResult
    public func createUserAndLogin(userName: String, color: Color) -> Promise<UserData> {
        return firstly {
            self.usersManager.createUser(with: userName, color: color)
        }.then {
            self.login(userName: userName)
        }
    }

    // FIXME: Deal with weak self everywhere!
    @discardableResult
    public func login(userName: String) -> Promise<UserData> {
        return firstly {
            self.sendLogin(for: userName)
        }.then {
            self.waitLoginResponse()
        }.map { userData in
            self.loggedInUserData = userData
            return userData
        }
    }

    @discardableResult
    public func logout(userName: String) -> Promise<UserData> {
        return firstly {
            self.sendLogout(for: userName)
        }.then {
            self.waitLogoutResponse()
        }.map { userData in
            self.loggedInUserData = nil
            return userData
        }
    }
}

extension SessionManager {
    public func assembleInteractions() {
        networkManager.onConnectionEstablished
            .bind { [weak self] in
                guard let self = self else { return }
                guard let userName = self.loggedInUserData?.userName else { return }
                self.login(userName: userName)
            }.disposed(by: disposeBag)
    }
}

extension SessionManager {
    func sendLogin(for userName: String) -> Promise<Void> {
        let message = SessionManagerMessage.login(userName: userName)
        return networkManager.send(message)
    }

    func sendLogout(for userName: String) -> Promise<Void> {
        let message = SessionManagerMessage.logout(userName: userName)
        return networkManager.send(message)
    }

    func waitLoginResponse() -> Promise<UserData> {
        return .init() { promise in
            let compositeDisposable = CompositeDisposable()

            self.networkManager.onMessage
                .bind { message in
                    guard case .loginResponseSuccess(let userData) = message else { return }
                    promise.resolve(with: userData)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)

            self.networkManager.onMessage
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
        return .init() { promise in
            let compositeDisposable = CompositeDisposable()

            self.networkManager.onMessage
                .bind { message in
                    guard case .logoutResponseSuccess(let userData) = message else { return }
                    promise.resolve(with: userData)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)

            self.networkManager.onMessage
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
