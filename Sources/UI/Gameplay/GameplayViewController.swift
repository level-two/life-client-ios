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

import UIKit

class GameplayViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gameFieldView: UIView!
    
    struct Cell {
        var pos: CGPoint
    }
    
    struct PlayerCells {
        var color: UIColor
        var cells: [Cell]
    }
    
    var cellSize : CGFloat = 0
    var numCellsX: CGFloat = 0
    var numCellsY: CGFloat = 0
    var players  : [PlayerCells] = []
    
    
    var navigator: SceneNavigatorProtocol!
    var sessionManager: SessionProtocol!
    var networkManager: NetworkManagerProtocol!
    var user: User!
    
    func setupDependencies(navigator: SceneNavigatorProtocol, sessionManager: SessionProtocol, networkManager: NetworkManagerProtocol) {
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.networkManager = networkManager
        self.user = sessionManager.user.require()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //self.gameFieldView.frame = self.scrollView.bounds
        print(self.view.frame)
        print(self.scrollView.frame)
        print(self.gameFieldView.frame)
        print(self.gameFieldView.bounds)
        cellSize = 10.0
        numCellsX = (self.gameFieldView.bounds.width  / cellSize).rounded(.down)
        numCellsY = (self.gameFieldView.bounds.height / cellSize).rounded(.down)
        
        // Create random players and cells
        let numPlayers = 4
        for _ in 0..<numPlayers {
            var cells = [Cell]()
            let cellsNum = arc4random() % 200
            for _ in 0..<cellsNum {
                let x = CGFloat(arc4random()).truncatingRemainder(dividingBy: numCellsX)
                let y = CGFloat(arc4random()).truncatingRemainder(dividingBy: numCellsY)
                cells.append(Cell(pos: CGPoint(x: x, y: y)))
            }
            players.append(PlayerCells(color: .random, cells: cells))
        }
        
        // Draw player cells
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
            layer.strokeColor = player.color.cgColor
            
            self.gameFieldView.layer.addSublayer(layer)
        }
        
        // Draw grid
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
        gridLayer.lineWidth = 1
        self.gameFieldView.layer.addSublayer(gridLayer)
    }
}

extension GameplayViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.gameFieldView
    }
}

extension GameplayViewController {
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if self.scrollView.zoomScale == 1 {
            self.scrollView.zoom(to: zoomRectForScale(scale: self.scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            self.scrollView.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.gameFieldView.frame.size.height / scale
        zoomRect.size.width  = self.gameFieldView.frame.size.width  / scale
        let newCenter = self.scrollView.convert(center, from: self.gameFieldView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
}
