import Foundation

class Server {
    var connections = [Connection]()
    
    public func established(connection: Connection) {
        connections.append(connection)
        connection.onMessage { [weak self] message, connectionId in
            self?.processMessage(message, for: connectionId)
        }
    }
    
    func processMessage(_ message: Message, for connectionId: Int) {
        // TODO pass message to the GameplayModel
        /*
        switch message {
        case .placeCell(gameCycle: <#T##Int#>, cell: <#T##Cell#>):
            <#code#>
        default:
            <#code#>
        }
        */
        connections.filter { $0.connectionId != connectionId }.forEach { $0.transmit(message) }
    }
    
    // TODO Send update each 5 seconds
}
