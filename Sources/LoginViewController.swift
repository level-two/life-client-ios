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

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var playerNameTextField: UITextField!
    // TODO Busy notification view
    
    private var navigator: LoginNavigator?
    private var sessionManager: SessionManager?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerNameTextField.delegate = self
    }
    
    func setupDependencies(navigator: LoginNavigator, sessionManager: SessionManager) {
        self.navigator = navigator
        self.sessionManager = sessionManager
    }
    
    private func handleLoginButtonTap() {
        /*
        performLogin { [weak self] result in
            switch result {
            case .success(let user):
                self?.navigator.navigate(to: .loginCompleted(user: user))
            case .failure(let error):
                self?.show(error)
            }
        }
        */
    }
}

// UI Actions
extension LoginViewController {
    @IBAction func onNewPlayerButton() {
        navigator?.navigate(to: .createUser)
    }
    
    @IBAction func onLoginButton() {
        guard
            let playerName = playerNameTextField.text,
            playerName.isEmpty == false
        else {
            let alert = UIAlertController(title: "Alert", message: "Please enter player name to login", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if NetClient.shared.isConnectedToServer == false {
            let alert = UIAlertController(title: "Alert", message: "Failed to connect to server. Please check if network is available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Show busy view and block UI
        NetClient.shared.send(message: ["login":playerName])
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

// Events handling
extension LoginViewController {
    func subscribeToEvents() {
        NetClient.shared.onConnectionReceivedMessageEvent.addHandler(target: self, handler: LoginViewController.onConnectionReceivedMessage)
    }
    
    func unsubscribeFromEvents() {
        NetClient.shared.onConnectionReceivedMessageEvent.removeTarget(self)
    }
    
    func onConnectionReceivedMessage(message: [String:Any]) {
        print("Called onConnection received with message: \(message)")
        
        // Hide Busy view
        
        if let errorMessage = message["userLoggedIn"] as? String {
            let alert = UIAlertController(title: "Alert", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        guard
            let successDic = message["userLoggedIn"] as? [String:Any],
            let userId = successDic["userId"] as? String,
            let userName = successDic["userName"] as? String
        else {
            let alert = UIAlertController(title: "Alert", message: "Failed to login", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
}
