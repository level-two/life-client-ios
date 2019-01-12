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

protocol AppDelegateEvents: class {
    var onApplicationWillResignActive: Event<Void> { get }
    var onApplicationDidEnterBackground: Event<Void> { get }
    var onApplicationWillEnterForeground: Event<Void> { get }
    var onApplicationDidBecomeActive: Event<Void> { get }
    var onApplicationWillTerminate: Event<Void> { get }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AppDelegateEvents {
    var window: UIWindow?
    var dependencyContainer: DependencyContainer!
    
    let onApplicationWillResignActive = Event<Void>()
    let onApplicationDidEnterBackground = Event<Void>()
    let onApplicationWillEnterForeground = Event<Void>()
    let onApplicationDidBecomeActive = Event<Void>()
    let onApplicationWillTerminate = Event<Void>()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        dependencyContainer = DependencyContainer(appDelegateEvents: self, navigationController: navigationController)
        let loginViewController = dependencyContainer.makeLoginViewController()
        navigationController.viewControllers = [loginViewController]
        window?.rootViewController = navigationController
        return true
    }
    
    func setupDependencies(navigator: LoginNavigator, navigationController: UINavigationController) {
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        onApplicationWillResignActive.raise(with: ())
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        onApplicationDidEnterBackground.raise(with: ())
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        onApplicationWillEnterForeground.raise(with: ())
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        onApplicationDidBecomeActive.raise(with: ())
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        onApplicationWillTerminate.raise(with: ())
    }
}

