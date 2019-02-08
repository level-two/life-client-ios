import Foundation
import UIKit

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


