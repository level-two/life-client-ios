//: [Previous](@previous)

import Foundation
import UIKit
import PlaygroundSupport

public class GameFieldView: UIView {
    var cellSize : CGFloat = 20.0
    
    func addGridLayer(numCellsX: Int, numCellsY: Int) {
        let grid = CGMutablePath()
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
        gridLayer.backgroundColor = UIColor.white.cgColor
        self.layer.addSublayer(gridLayer)
    }
    
    func addCell(x: Int, y: Int, lifeTime: Double, color0: UIColor, color1: UIColor) {
        let rect = CGRect(x: cellSize*CGFloat(x), y: cellSize*CGFloat(y), width: cellSize, height: cellSize)
        
        let path = CGMutablePath()
        path.addRect(rect)
        let cellLayer = CAShapeLayer()
        cellLayer.path = path
        cellLayer.fillColor = color0.cgColor
        cellLayer.strokeColor = UIColor.black.cgColor
        self.layer.addSublayer(cellLayer)
        
        CATransaction.begin()
        let colorAnim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.fillColor))
        colorAnim.fromValue = color0.cgColor
        colorAnim.toValue = color1.cgColor
        colorAnim.duration = lifeTime
        CATransaction.setCompletionBlock{ cellLayer.removeFromSuperlayer() }
        cellLayer.add(colorAnim, forKey: nil)
        CATransaction.commit()
    }
}

public class GameFieldViewController: UIViewController {
    public let onTap = Observable<(x: Int, y: Int)>()
    public var numCellsX: Int = 1
    public var numCellsY: Int = 1
    
    let gameFieldView = GameFieldView()

    override public func loadView() {
        self.view = gameFieldView
        gameFieldView.backgroundColor = .white
        gameFieldView.addGridLayer(numCellsX: numCellsX, numCellsY: numCellsY)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture(_:)))
        gameFieldView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc
    func onTapGesture(_ sender: UIGestureRecognizer) {
        let touchLocation = sender.location(in: gameFieldView)
        let x = Int(touchLocation.x/gameFieldView.cellSize)
        let y = Int(touchLocation.y/gameFieldView.cellSize)
        onTap.notifyObservers((x: x, y: y))
    }
    
    public func addCell(x: Int, y: Int, lifeTime: Double) {
        gameFieldView.addCell(x: x, y: y, lifeTime: lifeTime, color0: .red, color1: .black)
    }
}

public class GameplayModel {
    public class GameFieldArray {
        var gameField: [[Double]]
        public let width: Int
        public let height: Int
        
        public init(_ width: Int, _ height: Int) {
            self.width = width
            self.height = height
            self.gameField = .init(repeating: .init(repeating: 0.0, count: height), count: width)
        }
        
        subscript(x: Int, y: Int) -> Double {
            get { let (ix, iy) = indicesFromCyclic(x, y); return gameField[ix][iy] }
            set { let (ix, iy) = indicesFromCyclic(x, y); gameField[ix][iy] = newValue }
        }
        
        private func indicesFromCyclic(_ x: Int, _ y: Int) -> (Int, Int) {
            var ix = x % width
            var iy = y % height
            if ix < 0 {
                ix = width + ix
            }
            if iy < 0 {
                iy = height + iy
            }
            return (ix, iy)
        }
    }
    
    let numCellsX: Int = 20
    let numCellsY: Int = 30
    let lifeTime: Double = 5
    let timeStep: Double = 0.1
    var gameField: GameFieldArray
    var updateTimer: Timer?
    let gameFieldViewController: GameFieldViewController
    
    public init(gameFieldViewController: GameFieldViewController) {
        gameField = .init(numCellsX, numCellsY)

        self.gameFieldViewController = gameFieldViewController
        gameFieldViewController.numCellsX = numCellsX
        gameFieldViewController.numCellsY = numCellsY
        gameFieldViewController.onTap.addObserver(self) { [weak self] x, y in
            guard let self = self else { return }
            
            if self.gameField[x,y] == 0.0 {
                self.gameField[x,y] = self.lifeTime
                self.gameFieldViewController.addCell(x: x, y: y, lifeTime: self.lifeTime)
            }
        }

        self.updateTimer = Timer.scheduledTimer(timeInterval: timeStep, target: self, selector: #selector(GameplayModel.update), userInfo: nil, repeats: true)
    }

    func getNeighborsCount(_ x: Int, _ y: Int) -> Int {
        return [
            gameField[x-1, y-1],
            gameField[x-1, y  ],
            gameField[x-1, y+1],
            gameField[x  , y-1],
            gameField[x  , y+1],
            gameField[x+1, y-1],
            gameField[x+1, y  ],
            gameField[x+1, y+1]
            ].filter { $0 > 0 }.count
    }
    
    @objc func update() {
        var expiredCells = [(x: Int, y: Int)]()
        for x in 0..<numCellsX {
            for y in 0..<numCellsY {
                if gameField[x,y] > 0 {
                    gameField[x,y] -= timeStep
                    
                    if gameField[x,y] <= 0 {
                        expiredCells.append((x: x, y: y))
                    }
                }
            }
        }
        
        var cellsToPut = [(x: Int, y: Int)]()
        var cellsToRemove = [(x: Int, y: Int)]()
        
        expiredCells.forEach { x, y in
            let neighborsCount = getNeighborsCount(x, y)
            
            // give birth if there are min two cells of the same user
            if neighborsCount == 3 {
                cellsToPut.append((x,y))
            }
            
            // death
            if neighborsCount < 2 || neighborsCount > 3 {
                cellsToRemove.append((x,y))
            }
        
            [(x-1, y-1),
             (x-1, y  ),
             (x-1, y+1),
             (x  , y-1),
             (x  , y+1),
             (x+1, y-1),
             (x+1, y  ),
             (x+1, y+1)]
            .forEach { x, y in
                if gameField[x,y] <= 0 && getNeighborsCount(x, y) == 3 {
                    cellsToPut.append((x,y))
                }
            }
        }

        cellsToRemove.forEach { x, y in gameField[x,y] = 0 }
        cellsToPut.forEach { x, y in
            gameField[x,y] = lifeTime
            self.gameFieldViewController.addCell(x: x, y: y, lifeTime: self.lifeTime)
        }
    }
}



let gameFieldViewController = GameFieldViewController()
let gameplayModel = GameplayModel(gameFieldViewController: gameFieldViewController)
gameFieldViewController.view.frame = CGRect(x: 0, y: 0, width: 400, height: 600)
PlaygroundPage.current.liveView = gameFieldViewController
PlaygroundPage.current.needsIndefiniteExecution = true

//: [Next](@next)
