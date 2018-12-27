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
}

// UI Actions
extension LoginViewController {
    @IBAction func onNewPlayerButton() {
        navigator?.navigate(to: .createUser)
    }
    
    @IBAction func onLoginButton() {
        guard
            let userName = playerNameTextField.text,
            userName.isEmpty == false
        else {
            alert("Please enter player name to login")
            return
        }
        
        let future = sessionManager?.login(userName: userName)
        
        future?.observe { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .value:
                self.navigator?.navigate(to: .loginCompleted)
            case .error(let error):
                self.alert(error.localizedDescription)
            }
        }
    }
    
    func alert(_ description: String) {
        let alert = UIAlertController(title: "Alert", message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
