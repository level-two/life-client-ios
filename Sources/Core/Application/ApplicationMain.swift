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

import UIKit

@UIApplicationMain
class ApplicationMain: UIResponder, UIApplicationDelegate, ApplicationStateObservable {
    var window: UIWindow?
    var dependencyContainer: DependencyContainer!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Build
        let networkManager       = NetworkManager()
        let usersManager         = UsersManager(networkManager)
        let sessionManager       = SessionManager(networkManager, usersManager)
        
        let navigationController = UINavigationController()
        let storyboard           = UIStoryboard(name: "Main", bundle: nil)
        let sceneNavigator       = SceneNavigator(dependencyContainer, navigationController)
        self.dependencyContainer = DependencyContainer(storyboard, networkManager, usersManager, sessionManager, sceneNavigator)

        window?.rootViewController = navigationController
        navigationController.isNavigationBarHidden = true
        //navigationController.viewControllers = []

        // run!
        networkManager.run()
        sceneNavigator.navigate(to: .login)

        return true
    }
}
