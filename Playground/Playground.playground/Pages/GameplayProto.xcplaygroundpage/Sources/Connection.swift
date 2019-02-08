import Foundation

class Connection {
    typealias ReceiveCallback = (Message, Int) -> Void
    
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
    
    init(network: Network, connectionId: Int, peerId: Int) {
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
