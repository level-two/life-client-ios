import UIKit
import PlaygroundSupport

class PlayerController : UIViewController {
    var connection: Connection!
    
    struct PlayerCells {
        var color: UIColor
        var cells: [Cell]
    }
    
    var cellSize : CGFloat = 0
    var numCellsX: CGFloat = 0
    var numCellsY: CGFloat = 0
    var players  : [PlayerCells] = []
    
    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        cellSize = 10.0
        numCellsX = (self.view.bounds.width  / cellSize).rounded(.down)
        numCellsY = (self.view.bounds.height / cellSize).rounded(.down)
        
        let numPlayers = 4
        for _ in 0..<numPlayers {
            var cells = [Cell]()
            let cellsNum = arc4random() % 200
            for _ in 0..<cellsNum {
                let x = CGFloat(arc4random()).truncatingRemainder(dividingBy: numCellsX)
                let y = CGFloat(arc4random()).truncatingRemainder(dividingBy: numCellsY)
                cells.append(Cell(pos: (x: x, y: y)))
            }
            players.append(PlayerCells(color: .random, cells: cells))
        }
        
        players.forEach { [weak self] player in
            guard let self = self else { return }
            
            let cellSize = self.cellSize
            let cellsPath = CGMutablePath()
            
            player.cells.forEach { cell in
                cellsPath.addRect(CGRect(x: cell.pos.x * cellSize,
                                         y: cell.pos.y * cellSize,
                                         width: cellSize,
                                         height: cellSize))
            }
            let layer = CAShapeLayer()
            layer.path = cellsPath
            layer.fillColor = player.color.cgColor
            
            self.view.layer.addSublayer(layer)
        }
        
        let grid = CGMutablePath()
        for x in 0...Int(numCellsX) {
            grid.move(to: CGPoint(x: CGFloat(x)*cellSize, y:0))
            grid.addLine(to: CGPoint(x: CGFloat(x)*cellSize, y: cellSize*numCellsY))
        }
        for y in 0...Int(numCellsY) {
            grid.move(to: CGPoint(x: 0, y: CGFloat(y)*cellSize))
            grid.addLine(to: CGPoint(x: cellSize*numCellsX, y: CGFloat(y)*cellSize))
        }
        let gridLayer = CAShapeLayer()
        gridLayer.path = grid
        gridLayer.strokeColor = UIColor.black.cgColor
        self.view.layer.addSublayer(gridLayer)
    }
    
    public func established(connection: Connection) {
        self.connection = connection
        connection.onMessage { [weak self] message, _ in
            self?.processMessage(message)
        }
    }
    
    func processMessage(_ message: Message) {
        // TODO pass message to the GameplayModel
        switch  message {
        case .newCycle(gameCycle: var cycle):
            ()
        case .placeCell(gameCycle: var cycle, cell: var cell):
            ()
        }
    }
}


struct Cell {
    var pos: (x: Int, y: Int)
    var userId: Int
    var color: UIColor
}

enum Message {
    case placeCell(gameCycle: Int, cell: Cell)
    case newCycle(gameCycle: Int)
}


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
        connections.filter { $0.connectionId != connectionId }.forEach { $0.transmit(message) }
    }
    
    // TODO Send update each 5 seconds
}

class GameplayModelBase {
    var width  = 16
    var height = 16
    var gameField: [Cell?]
    
    init() {
        gameField = [Cell?].init(repeating: nil, count: width*height)
    }
    
    func placeCell(cell: Cell) -> Bool {
        let (x, y) = cell.pos
        gameField[y*width+x] = cell
        
        // TODO implement cycles and conflicts resolving
    }
    
    func canPlaceCell(cell: Cell) -> Bool {
        return true
    }
}

class ServerGameplayModel: GameplayModelBase {
    override func canPlaceCell(cell: Cell) -> Bool {
        let (x, y) = cell.pos
        return gameField[y*width+x] == nil
    }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
