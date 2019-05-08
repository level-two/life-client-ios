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

class UsersManager {
    public enum UsersManagerError: Error {
        case operationTimeout
    }
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

//    public func userData(for userId: UserId) -> Promise<UserData> {
//    }
//
//    public func userData(for userName: String) -> Promise<UserData> {
//        return database.userData(with: userName)
//    }

//    func requestUserData(for userId: UserId) -> Promise<Void> {
//        return networkManager.send(message)
//    }
//
//    func waitForUserDataResponse() -> Promise<UserData> {
//        return .init() { [weak self] promise in
//
//        }
//    }
    
    public func createUser(with userName: String, color: Color) -> Promise<UserData> {
        return firstly {
            sendCreateUserMessage(with: userName, color: color)
        }.then {
            waitCreateUserResponse()
        }
    }

    let networkManager: NetworkManager?
}

extension UsersManager: UserCreationManager {
    func sendCreateUserMessage(with userName: String, color: Color) -> Promise<Void> {
        return networkManager.send(.createUser(userName: userName, color: color))
    }

    func waitCreateUserResponse() -> Promise<UserData> {
        return .init() { [weak self] promise in
            let compositeDisposable = CompositeDisposable()

            self?.networkManager?.onMessage
                .bind { message in
                    guard case .createUserSuccess(let userData) = message else { return }
                    promise.resolve(with: userData)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)

            self?.networkManager?.onMessage
                .bind { message in
                    guard case .createUserError(let error) = message else { return }
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
