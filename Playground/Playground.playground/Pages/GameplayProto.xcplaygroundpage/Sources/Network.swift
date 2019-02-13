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

public class Network {
    private var freeConnectionId = 0
    private var connections = [Connection]()
    
    public init() {
    }
    
    public func establishConnection() -> (Connection, Connection) {
        let aliceId = freeConnectionId
        let bobId   = freeConnectionId + 1
        freeConnectionId += 2
        
        let alice = Connection(network: self, connectionId: aliceId, peerId: bobId)
        let bob   = Connection(network: self, connectionId: bobId, peerId: aliceId)
        
        connections += [alice, bob]
        
        return (alice, bob)
    }
    
    public func transmit(_ message: Message, to peerId: Int) {
        // TODO introduce short constant delay
        // TODO introduce delay jitter
        // TODO introduce long delays
        // TODO introduce packet loss
        print("Network message to \(peerId): \(message)")
        connections.first { $0.connectionId == peerId }?.receive(message)
    }
}
