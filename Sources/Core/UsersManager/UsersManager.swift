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

//protocol UserInfoProvider {
//    func userData(for userId: UserId) -> Promise<UserData>
//    func userData(for userName: String) -> Promise<UserData>
//}

protocol UserCreationManager {
    func createUser(with userName: String, color: Color) -> Promise<UserData>
}

class UsersManager {
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
    
    fileprivate weak var networkManager: NetworkManager?
}

extension UsersManager: UserCreationManager {
    func createUser(with userName: String, color: Color) -> Promise<UserData> {
        return firstly {
            sendCreateUserMessage(with: userName, color: color)
        }.then {
            waitCreateUserResponse()
        }
    }
    
    func sendCreateUserMessage(with userName: String, color: Color) -> Promise<Void> {
        return networkManager.send(.createUser(userName: userName, color: color))
    }
    
    func waitCreateUserResponse() -> Promise<UserData> {
        return .init() { [weak self] promise in
            let disposeBag = DisposeBag()
            
            networkManager.onMessage.bind { message in
                guard case .createUserSuccess(let userData) = message else { return }
                
                promise.resolve(with: userData)
                disposeBag.reset()
            }.disposed(by: disposeBag)
            
            networkManager.onMessage.bind { message in
                guard case .createUserError(let error) = message else { return }
                
                promise.reject(error)
                disposeBag.reset()
            }.disposed(by: disposeBag)
            
            // TODO: Add operation timeout check
        }
    }
}
