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

extension SessionManager {
    @discardableResult
    public func createUserAndLogin(userName: String, color: Color) -> Promise<UserData> {
        return firstly {
            usersManager.createUser(with: userName, color: color)
        }.then {
            login(userName: userName)
        }
    }
    
    // FIXME: Deal with weak self everywhere!
    @discardableResult
    public func login(userName: String) -> Promise<UserData> {
        return firstly {
            sendLogin(for: userName)
        }.then {
            waitLoginResponse()
        }.map {
            loggedInUserData = $0
            return userData
        }
    }
    
    @discardableResult
    public func logout(userName: String) -> Promise<UserData> {
        return firstly {
            sendLogout(for: userName)
        }.then {
            waitLogoutResponse()
        }.map {
            loggedInUserData = nil
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
