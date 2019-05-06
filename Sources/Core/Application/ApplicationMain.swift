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

enum ApplicationState {
    /// Sent when the application is about to move from active to inactive state.
    /// This can occur for certain types of temporary interruptions (such as an
    /// incoming phone call or SMS message) or when the user quits the application
    /// and it begins the transition to the background state.
    ///
    /// Use this method to pause ongoing tasks, disable timers, and invalidate
    /// graphics rendering callbacks. Games should use this method to pause the game.
    case willResignActive

    /// Use this method to release shared resources, save user data, invalidate timers,
    /// and store enough application state information to restore your application to
    /// its current state in case it is terminated later.
    ///
    /// If your application supports background execution, this method is called
    /// instead of applicationWillTerminate: when the user quits.
    case didEnterBackground

    /// Called as part of the transition from the background to the active state;
    /// here you can undo many of the changes made on entering the background.
    case willEnterForeground

    /// Restart any tasks that were paused (or not yet started) while the application was inactive.
    ///
    /// If the application was previously in the background, optionally refresh the user interface.
    case didBecomeActive

    /// Called when the application is about to terminate. Save data if appropriate.
    case willTerminate
}

protocol ApplicationStateObservable {
    var appStateObservable: Observable<ApplicationState> { get }
}

@UIApplicationMain
class ApplicationMain: UIResponder, UIApplicationDelegate, ApplicationStateObservable {
    var appStateObservable = Observable<ApplicationState>()
    var window: UIWindow?
    var dependencyContainer: DependencyContainer!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Build
        let navigationController = UINavigationController()
        let storyboard           = UIStoryboard(name: "Main", bundle: nil)
        let networkManager       = NetworkManager()
        let sessionManager       = SessionManager()
        let sceneNavigator       = SceneNavigator()
        self.dependencyContainer = DependencyContainer()

        // Assemble dependencies
        networkManager.setupDependencies(appState: self)
        sessionManager.setupDependencies(networkManager: networkManager)
        sceneNavigator.setupDependencies(viewControllerFactory: dependencyContainer, navigationController: navigationController)
        dependencyContainer.setupDependencies(storyboard: storyboard, networkManager: networkManager, sessionManager: sessionManager, sceneNavigator: sceneNavigator)
        window?.rootViewController = navigationController

        // Configure
        navigationController.isNavigationBarHidden = true
        //navigationController.viewControllers = []

        // run!
        networkManager.run()
        sceneNavigator.navigate(to: .login)

        return true
    }

    func setupDependencies(navigator: SceneNavigator, navigationController: UINavigationController) {

    }

    func applicationWillResignActive(_ application: UIApplication) {
        appStateObservable.notifyObservers(.willResignActive)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        appStateObservable.notifyObservers(.didEnterBackground)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        appStateObservable.notifyObservers(.willEnterForeground)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        appStateObservable.notifyObservers(.didBecomeActive)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        appStateObservable.notifyObservers(.willTerminate)
    }
}
