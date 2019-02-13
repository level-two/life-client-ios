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

import PlaygroundSupport
import UIKit

let network     = Network()

let server      = Server()
let serverModel = ServerGameplayModel(server: server)

var clients      = [Client]()
var clientModels = [ClientGameplayModel]()
let clientViews  = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))

for i in 0...3 {
    let client = Client()
    
    let (conn1, conn2) = network.establishConnection()
    client.established(connection: conn1)
    server.established(connection: conn2)
    
    let clientViewController = ClientViewController()
    clientViewController.view.frame = CGRect(x: 200 * (i % 2), y: 200*(i/2), width: 180, height: 180)
    
    let clientModel = ClientGameplayModel(client: client, clientViewController: clientViewController)
    
    clients.append(client)
    clientModels.append(clientModel)
    clientViews.addSubview(clientViewController.view)
}

PlaygroundPage.current.liveView = clientViews
PlaygroundPage.current.needsIndefiniteExecution = true
