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

class CreateUserViewController: UIViewController, UITextFieldDelegate {
    private var navigator: SceneNavigator!
    private var sessionManager: SessionManager!
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var colorPickSlider: ColorPickSlider!
    @IBOutlet weak var colorPreviewLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIView!
    
    func setupDependencies(navigator: SceneNavigator, sessionManager: SessionManager) {
        self.navigator = navigator
        self.sessionManager = sessionManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userNameTextField.delegate = self
        self.colorPreviewLabel.backgroundColor = self.colorPickSlider.pickedColor
        self.activityIndicatorView.isHidden = true
    }
    
    @IBAction func onCancelButton() {
        self.navigator.navigate(to: .login)
        userNameTextField.resignFirstResponder()
    }
    
    @IBAction func onCreateButton() {
        guard
            let userName = userNameTextField.text,
            userName.isEmpty == false
        else {
            alert("Please enter player name to login")
            return
        }
        
        activityIndicatorView.isHidden = false
        userNameTextField.resignFirstResponder()
        
        let color = self.colorPickSlider.pickedColor
        sessionManager.createUserAndLogin(userName: userName, color: color).observe { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicatorView.isHidden = true
            }
            
            switch result {
            case .value:
                self.navigator.navigate(to: .gameplay)
            case .error(let error):
                self.alert(error.localizedDescription)
            }
        }
    }
    
    @IBAction func onColorSliderValueChanged() {
        self.colorPreviewLabel.backgroundColor = self.colorPickSlider.pickedColor
    }
}

// Text field service code
extension CreateUserViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
