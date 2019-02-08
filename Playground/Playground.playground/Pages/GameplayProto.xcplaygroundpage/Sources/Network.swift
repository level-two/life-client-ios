import Foundation

class Network {
    private var freeConnectionId = 0
    private var connections = [Connection]()
    
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
        connections.first { $0.connectionId == peerId }?.receive(message)
    }
}
