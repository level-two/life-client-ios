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

// Here we define a set of supported destinations using an
// enum, and we can also use associated values to add support
// for passing arguments from one screen to another.
enum Destination {
    case login
    case createUser
    case gameplay
    case chat
}

protocol SceneNavigatorProtocol {
    func navigate(to destination: Destination)
}

class SceneNavigator: SceneNavigatorProtocol {
    // In most cases it's totally safe to make this a strong
    // reference, but in some situations it could end up
    // causing a retain cycle, so better be safe than sorry :)
    private weak var navigationController: UINavigationController!
    private      var factory: ViewControllerFactory!
    
    func setupDependencies(viewControllerFactory factory: ViewControllerFactory, navigationController: UINavigationController) {
        self.factory = factory
        self.navigationController = navigationController
    }
    
    func navigate(to destination: Destination) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let viewController = self.makeViewController(for: destination)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func makeViewController(for destination: Destination) -> UIViewController {
        switch destination {
        case .login:
            return factory.makeLoginViewController()
        case .createUser:
            return factory.makeCreateUserViewController()
        case .gameplay:
            return factory.makeGameplayViewController()
        case .chat:
            return factory.makeChatViewController()
        }
    }
}
