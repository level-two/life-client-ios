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

public class ClientViewController: UIViewController {
    var cellSize : CGFloat = 10.0
    
    override public func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .white
    }
    
    public func draw(with gameField: GameField) {
        self.view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let cells   = gameField.gameField.compactMap{ $0 }
        let userIds = cells.map{ $0.userId }.orderedSet
        
        userIds.forEach { userId in
            let cellsPerUserId = cells.filter{ $0.userId == userId }
            let cellsPath = CGMutablePath()
            cellsPerUserId.forEach { cell in
                cellsPath.addRect(CGRect(x: CGFloat(cell.pos.x) * cellSize,
                                         y: CGFloat(cell.pos.y) * cellSize,
                                         width: cellSize,
                                         height: cellSize))
            }
            let layer = CAShapeLayer()
            layer.path = cellsPath
            layer.fillColor = cellsPerUserId.first!.color.cgColor
            self.view.layer.addSublayer(layer)
        }
        
        let grid = CGMutablePath()
        let numCellsX = gameField.width
        let numCellsY = gameField.height
        for x in 0...numCellsX {
            grid.move(to: CGPoint(x: CGFloat(x)*cellSize, y:0))
            grid.addLine(to: CGPoint(x: CGFloat(x)*cellSize, y: cellSize*CGFloat(numCellsY)))
        }
        for y in 0...numCellsY {
            grid.move(to: CGPoint(x: 0, y: CGFloat(y)*cellSize))
            grid.addLine(to: CGPoint(x: cellSize*CGFloat(numCellsX), y: CGFloat(y)*cellSize))
        }
        let gridLayer = CAShapeLayer()
        gridLayer.path = grid
        gridLayer.strokeColor = UIColor.black.cgColor
        self.view.layer.addSublayer(gridLayer)
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1.0)
    }
}

extension Array where Element:Hashable {
    var orderedSet: Array {
        var unique = Set<Element>()
        return self.filter { unique.insert($0).inserted }
    }
}
