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

protocol ViewControllerFactory {
    func makeLoginViewController() -> LoginViewController
    func makeCreateUserViewController() -> CreateUserViewController
    func makeChatViewController() -> ChatViewController
}

protocol NavigatorFactory {
    func makeLoginNavigator() -> LoginNavigator
}

class DependencyContainer {
    private lazy var storyboard = UIStoryboard(name: "Main", bundle: nil)
    private lazy var networkEvents = NetworkEvents()
    private lazy var networkManager = NetworkManager(networkEvents: networkEvents)
    private lazy var sessionManager = SessionManager(networkManager: networkManager, networkEvents: networkEvents)
    private lazy var loginNavigator = LoginNavigator(viewControllerFactory: self, navigationController: navigationController)
    
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
}

extension DependencyContainer: NavigatorFactory {
    
    func makeLoginNavigator() -> LoginNavigator {
        return LoginNavigator(viewControllerFactory: self, navigationController: navigationController)
    }
}

extension DependencyContainer: ViewControllerFactory {
    func makeLoginViewController() -> LoginViewController {
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        vc.setupDependencies(navigator: loginNavigator, sessionManager: sessionManager)
        return vc
    }
    
    func makeCreateUserViewController() -> CreateUserViewController {
        let vc = storyboard.instantiateViewController(withIdentifier: "CreateUserViewController") as! CreateUserViewController
        vc.setupDependencies(navigator: loginNavigator, sessionManager: sessionManager)
        return vc
    }
    
    func makeChatViewController() -> ChatViewController {
        let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.setupDependencies(navigator: loginNavigator, sessionManager: sessionManager, networkManager: networkManager, networkEvents: networkEvents)
        return vc
    }
}
