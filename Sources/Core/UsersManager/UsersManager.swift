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
        case userCreateError(error: String)
        case userDataRequestError(error: String)
    }

    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    public func userData(for userId: UserId) -> Promise<UserData> {
        return .init { promise in
            var userData: UserData?

            serialQueue.sync {
                userData = self.usersData.first(where: { $0.userId == userId })
            }

            if let userData = userData {
                promise.fulfill(userData)
                return
            }

            firstly {
                self.sendUserDataRequest(with: userId)
            }.then {
                self.waitUserDataResponse()
            }.done { userData in
                guard userData.userId == userId else { return }

                promise.fulfill(userData)

                self.serialQueue.async {
                    guard !self.usersData.contains(where: { $0.userId == userData.userId }) else { return }
                    self.usersData.append(userData)
                }
            }.catch { error in
                promise.reject(error)
            }
        }
    }

    public func createUser(with userName: String, color: Color) -> Promise<UserData> {
        return firstly {
            self.sendCreateUserMessage(with: userName, color: color)
        }.then {
            self.waitCreateUserResponse()
        }
    }

    var usersData: [UserData] = []
    let serialQueue = DispatchQueue(label: "life.client.usersManagerQueue")
    let networkManager: NetworkManager
}

extension UsersManager {
    func sendCreateUserMessage(with userName: String, color: Color) -> Promise<Void> {
        let message = UsersManagerMessage.createUser(userName: userName, color: color)
        return networkManager.send(message.json)
    }

    func waitCreateUserResponse() -> Promise<UserData> {
        return .init() { promise in
            let compositeDisposable = CompositeDisposable()

            let decodedMessage = networkManager.onMessage
                .compactMap { try? UsersManagerMessage(from: $0) }

            decodedMessage.bind { message in
                    guard case .createUserSuccess(let userData) = message else { return }
                    promise.fulfill(userData)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)

            decodedMessage.bind { message in
                    guard case .createUserError(let error) = message else { return }
                    promise.reject(UsersManagerError.userCreateError(error: error))
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)

            let timeout = ApplicationSettings.operationTimeout

            Observable<Int>
                .timer(.init(timeout), period: nil, scheduler: MainScheduler.instance)
                .bind { _ in
                    promise.reject(UsersManagerError.operationTimeout)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
        }
    }

    func sendUserDataRequest(with userId: UserId) -> Promise<Void> {
        let message = UsersManagerMessage.userDataRequest(userId: userId)
        return networkManager.send(message.json)
    }

    func waitUserDataResponse() -> Promise<UserData> {
        return .init() { promise in
            let compositeDisposable = CompositeDisposable()

            let decodedMessage = networkManager.onMessage
                .compactMap { try? UsersManagerMessage(from: $0) }

            decodedMessage.bind { message in
                guard case .userDataRequestSuccess(let userData) = message else { return }
                promise.fulfill(userData)
                compositeDisposable.dispose()
            }.disposed(by: compositeDisposable)

            decodedMessage.bind { message in
                guard case .userDataRequestError(let error) = message else { return }
                promise.reject(UsersManagerError.userDataRequestError(error: error))
                compositeDisposable.dispose()
            }.disposed(by: compositeDisposable)

            let timeout = ApplicationSettings.operationTimeout

            Observable<Int>
                .timer(.init(timeout), period: nil, scheduler: MainScheduler.instance)
                .bind { _ in
                    promise.reject(UsersManagerError.operationTimeout)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
        }
    }
}
