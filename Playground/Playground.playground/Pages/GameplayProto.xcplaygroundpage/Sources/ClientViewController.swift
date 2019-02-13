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
    public let gameFieldView = ClientView()
    public let onCellTapped = Observable<(x: Int, y: Int)>()
    
    override public func loadView() {
        self.view = gameFieldView
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture(_:)))
        gameFieldView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    public func draw(with gameField: GameField) {
        gameFieldView.draw(with: gameField)
    }
    
    @objc
    func onTapGesture(_ sender: UIGestureRecognizer) {
        let touchLocation = sender.location(in: gameFieldView)
        let cellPos = (x: Int(touchLocation.x/gameFieldView.cellSize),
                       y: Int(touchLocation.y/gameFieldView.cellSize))
        onCellTapped.notifyObservers(cellPos)
    }
}
