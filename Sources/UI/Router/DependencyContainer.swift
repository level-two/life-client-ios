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
    func makeGameplayViewController() -> GameplayViewController
    func makeChatViewController() -> ChatViewController
}

class DependencyContainer {
    private var storyboard: UIStoryboard!
    private var networkManager: NetworkManagerProtocol!
    private var sessionManager: SessionProtocol!
    private var sceneNavigator: SceneNavigatorProtocol!

    func setupDependencies(storyboard: UIStoryboard, networkManager: NetworkManagerProtocol,
                           sessionManager: SessionProtocol, sceneNavigator: SceneNavigatorProtocol) {
        self.storyboard     = storyboard
        self.networkManager = networkManager
        self.sessionManager = sessionManager
        self.sceneNavigator = sceneNavigator
    }
}

extension DependencyContainer: ViewControllerFactory {
    func makeLoginViewController() -> LoginViewController {
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        vc.setupDependencies(navigator: sceneNavigator, sessionManager: sessionManager)
        return vc
    }

    func makeCreateUserViewController() -> CreateUserViewController {
        let vc = storyboard.instantiateViewController(withIdentifier: "CreateUserViewController") as! CreateUserViewController
        vc.setupDependencies(navigator: sceneNavigator, sessionManager: sessionManager)
        return vc
    }

    func makeChatViewController() -> ChatViewController {
        let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.setupDependencies(navigator: sceneNavigator, sessionManager: sessionManager, networkManager: networkManager)
        return vc
    }

    func makeGameplayViewController() -> GameplayViewController {
        let vc = storyboard.instantiateViewController(withIdentifier: "GameplayViewController") as! GameplayViewController
        vc.setupDependencies(navigator: sceneNavigator, sessionManager: sessionManager, networkManager: networkManager)
        return vc
    }
}
