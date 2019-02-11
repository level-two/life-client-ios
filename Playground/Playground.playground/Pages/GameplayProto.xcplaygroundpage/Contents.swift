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

let server = Server()
let serverGameplayModel = ServerGameplayModel(server: server)

let client = Client()
let clientViewController = ClientViewController()
let clientGameplayModel = ClientGameplayModel(client: client, clientViewController: clientViewController)

let network = Network()

let (conn1, conn2) = network.establishConnection()
client.established(connection: conn1)
server.established(connection: conn2)

PlaygroundPage.current.liveView = clientViewController
