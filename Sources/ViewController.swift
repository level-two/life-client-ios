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

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NetClient.shared.onConnectionEstablishedEvent.addHandler(target: self, handler: ViewController.onConnectionEstablished)
        NetClient.shared.onConnectionClosedEvent.addHandler(target: self, handler: ViewController.onConnectionClosed)
        NetClient.shared.onConnectionFailedEvent.addHandler(target: self, handler: ViewController.onConnectionFailed)
        NetClient.shared.onConnectionReceivedMessageEvent.addHandler(target: self, handler: ViewController.onConnectionReceivedMessage)
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
