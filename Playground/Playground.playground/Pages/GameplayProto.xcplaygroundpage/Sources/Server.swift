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

public class Server {
    var connections = [Connection]()
    let onMessage = Observable<Message>()

    public init() {
    }

    public func established(connection: Connection) {
        connections.append(connection)
        connection.onMessage { [weak self] message, _ in
            self?.onMessage.notifyObservers(message)
        }
    }

    public func sendBroadcast(message: Message) {
        DispatchQueue.main.async { [weak self] in
            self?.connections.forEach { $0.transmit(message) }
        }
    }
}
