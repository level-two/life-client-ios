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

    var players: [PlayerCells] = []

    func setupDependencies(_ sceneNavigator: SceneNavigatorProtocol, _ sessionManager: SessionManager, _ gameplay: Gameplay) {
        self.presenter = GameplayPresenter(self)
        self.interactions = GameplayInteractions(sceneNavigator, sessionManager, gameplay, presenter)
    }

    func drawGameField(with viewData: GameFieldViewData) {
        let viewSize = self.gameFieldView.bounds.size
        let cellSize = min(viewSize.width  / CGFloat(viewData.fieldWidth),
                           viewSize.height / CGFloat(viewData.fieldHeight))

        // Draw player cells
        let colors = viewData.cells.map { $0.color }.unique

        colors.forEach { color in
            let path = CGMutablePath()

            viewData.cells.filter { $0.color == color }.forEach { cell in
                path.addRect(.init(x: CGFloat(cell.pos.x) * cellSize,
                                   y: CGFloat(cell.pos.y) * cellSize,
                                   width: cellSize,
                                   height: cellSize))
            }

            let layer = CAShapeLayer()
            layer.path = path
            layer.fillColor = color.cgColor
            layer.strokeColor = color.cgColor

            self.gameFieldView.layer.addSublayer(layer)
        }

        // Draw grid
        let grid = CGMutablePath()

        for x in 0...viewData.fieldWidth {
            grid.move(to: .init(x: CGFloat(x)*cellSize, y: 0))
            grid.addLine(to: .init(x: CGFloat(x) * cellSize, y: CGFloat(viewData.fieldHeight) * cellSize))
        }

        for y in 0...viewData.fieldHeight {
            grid.move(to: .init(x: 0, y: CGFloat(y) * cellSize))
            grid.addLine(to: .init(x: CGFloat(viewData.fieldWidth) * cellSize, y: CGFloat(y) * cellSize))
        }

        let gridLayer = CAShapeLayer()
        gridLayer.path = grid
        gridLayer.strokeColor = UIColor.black.cgColor
        gridLayer.lineWidth = 1

        self.gameFieldView.layer.addSublayer(gridLayer)
    }

    private var presenter: GameplayPresenter!
    private var interactions: GameplayInteractions!
}

extension GameplayViewController: UIScrollViewDelegate {
    private func viewForZooming(in scrollView: UIScrollView) -> UIView? {
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

    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.gameFieldView.frame.size.height / scale
        zoomRect.size.width  = self.gameFieldView.frame.size.width  / scale
        let newCenter = self.scrollView.convert(center, from: self.gameFieldView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
}
