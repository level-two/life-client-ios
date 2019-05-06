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

public class Connection {
    public typealias ReceiveCallback = (Message, Int) -> Void

    // Public
    public var connectionId: Int {
        get {
            return connectionIdVal
        }
    }

    // Private
    weak var network: Network?
    let connectionIdVal: Int
    let peerId: Int
    var receiveCallback: ReceiveCallback?

    public init(network: Network, connectionId: Int, peerId: Int) {
        self.network = network
        self.connectionIdVal = connectionId
        self.peerId = peerId
    }

    public func transmit(_ message: Message) {
        network?.transmit(message, to: peerId)
    }

    public func receive(_ message: Message) {
        receiveCallback?(message, connectionId)
    }

    public func onMessage(_ callback: @escaping ReceiveCallback) {
        receiveCallback = callback
    }
}
