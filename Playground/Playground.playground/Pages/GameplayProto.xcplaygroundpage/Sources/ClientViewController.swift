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
import UIKit

class ClientViewController: UIViewController {
    struct PlayerCells {
        var color: UIColor
        var cells: [Cell]
    }
    
    var cellSize : CGFloat = 10.0
    var numCellsX = 16
    var numCellsY = 16
    var players  : [PlayerCells] = []
    
    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let numPlayers = 4
        for userId in 0..<numPlayers {
            var cells = [Cell]()
            let cellsNum = arc4random() % 200
            for _ in 0..<cellsNum {
                let x = Int.random(in:0..<numCellsX)
                let y = Int.random(in:0..<numCellsY)
                cells.append(Cell(pos: (x: x, y: y), userId: userId))
            }
            players.append(PlayerCells(color: .random, cells: cells))
        }
        
        players.forEach { [weak self] player in
            guard let self = self else { return }
            
            let cellSize = self.cellSize
            let cellsPath = CGMutablePath()
            
            player.cells.forEach { cell in
                cellsPath.addRect(CGRect(x: CGFloat(cell.pos.x) * cellSize,
                                         y: CGFloat(cell.pos.y) * cellSize,
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
            grid.addLine(to: CGPoint(x: CGFloat(x)*cellSize, y: cellSize*CGFloat(numCellsY)))
        }
        for y in 0...Int(numCellsY) {
            grid.move(to: CGPoint(x: 0, y: CGFloat(y)*cellSize))
            grid.addLine(to: CGPoint(x: cellSize*CGFloat(numCellsX), y: CGFloat(y)*cellSize))
        }
        let gridLayer = CAShapeLayer()
        gridLayer.path = grid
        gridLayer.strokeColor = UIColor.black.cgColor
        self.view.layer.addSublayer(gridLayer)
    }
}

class GameFieldView: UIView {
    
    func redraw(with gameField: GameField) {
        
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red:   .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue:  .random(in: 0...1),
                       alpha: 1.0)
    }
}
