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
import PromiseKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var playerNameTextField: UITextField!

    private var navigator: SceneNavigatorProtocol!
    private var sessionManager: SessionManager!
    @IBOutlet weak var activityIndicatorView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        playerNameTextField.delegate = self
        activityIndicatorView.isHidden = true

        guard
            ApplicationSettings.autologinEnabled == true,
            let autologinUserName = ApplicationSettings.autologinUserName
            else { return }

        playerNameTextField.text = autologinUserName
        login(userName: autologinUserName)
    }

    func setupDependencies(navigator: SceneNavigatorProtocol, sessionManager: SessionManager) {
        self.navigator = navigator
        self.sessionManager = sessionManager
    }
}

// UI Actions
extension LoginViewController {
    @IBAction func onNewPlayerButton() {
        navigator.navigate(to: .createUser)
        playerNameTextField.resignFirstResponder()
    }

    @IBAction func onLoginButton() {
        guard
            let userName = playerNameTextField.text,
            userName.isEmpty == false
        else {
            alert("Please enter player name to login")
            return
        }
        login(userName: userName)
    }

    func login(userName: String) {
        activityIndicatorView.isHidden = false
        playerNameTextField.resignFirstResponder()

        firstly {
            sessionManager.login(userName: userName)
        }.done { _ in
            ApplicationSettings.autologinEnabled = true
            ApplicationSettings.autologinUserName = userName
            self.navigator.navigate(to: .gameplay)
        }.ensure(on: .main) {
            self.activityIndicatorView.isHidden = true
        }.catch { error in
            self.alert(error.localizedDescription)
        }
    }
}

// Text field service code
extension LoginViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
