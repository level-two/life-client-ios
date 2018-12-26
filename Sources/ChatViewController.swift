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

class ChatViewController: UITableViewController {
    let messages = ["Ololo", "Troloo", "NLO"]
    private var navigator: LoginNavigator?
    private var sessionManager: SessionManager?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupDependencies(navigator: LoginNavigator, sessionManager: SessionManager) {
        self.navigator = navigator
        self.sessionManager = sessionManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        subscribeToEvents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeFromEvents()
    }
    
}

// Events handling
extension ChatViewController {
    func subscribeToEvents() {
        NetClient.shared.onConnectionEstablishedEvent.addHandler(target: self, handler: ChatViewController.onConnectionEstablished)
        NetClient.shared.onConnectionClosedEvent.addHandler(target: self, handler: ChatViewController.onConnectionClosed)
        NetClient.shared.onConnectionFailedEvent.addHandler(target: self, handler: ChatViewController.onConnectionFailed)
        NetClient.shared.onConnectionReceivedMessageEvent.addHandler(target: self, handler: ChatViewController.onConnectionReceivedMessage)
    }
    
    func unsubscribeFromEvents() {
        NetClient.shared.onConnectionEstablishedEvent.removeTarget(self)
        NetClient.shared.onConnectionClosedEvent.removeTarget(self)
        NetClient.shared.onConnectionFailedEvent.removeTarget(self)
        NetClient.shared.onConnectionReceivedMessageEvent.removeTarget(self)
    }
    
    func onConnectionEstablished() {
        print("Called onConnectionEstablished")
        NetClient.shared.send(message: ["login":["userId":1]])
    }
    
    func onConnectionClosed() {
        print("Called onConnectionClosed")
    }
    
    func onConnectionReceivedMessage(message: [String:Any]) {
        print("Called onConnection received with message: \(message)")
    }
    
    func onConnectionFailed() {
        print("Called onConnectionFailed")
    }
}

// Table view handling
extension ChatViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        
        let message = messages[indexPath.row]
        cell.textLabel?.text = message
        cell.detailTextLabel?.text = "user buzzer"
        return cell
    }
}
