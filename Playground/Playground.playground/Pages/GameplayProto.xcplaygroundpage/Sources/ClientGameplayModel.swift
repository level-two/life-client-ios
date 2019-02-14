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

public class ClientGameplayModel {
    weak var client: Client!
    weak var clientViewController: ClientViewController!
    
    let userId: Int
    let color: UIColor
    let gameField: GameField
    var cycle = 0
    
    public init(client: Client, clientViewController: ClientViewController, width: Int, height: Int) {
        self.client               = client
        self.userId               = client.connection.connectionId
        self.color                = .random
        self.clientViewController = clientViewController
        self.gameField            = GameField(width, height)
        
        client.onMessage.addObserver(self) { [weak self] message in
            self?.onMessage(message)
        }
        
        clientViewController.onCellTapped.addObserver(self) { [weak self] cellPos in
            self?.onCellTapped(cellPos)
        }
        
        clientViewController.draw(with: gameField)
    }
    
    func onMessage(_ message: Message) {
        if case .new(let gameCycle) = message {
            // TODO: Handle connection loss - when several updates had been missed
            // - Request current game field state
            cycle = gameCycle
            gameField.updateForNewCycle()
        }
        
        if case .placeCell(let gameCycle, let cell) = message {
            if gameCycle == cycle {
                gameField.placeAcceptedCell(cell)
            }
            else if gameCycle == cycle-1 {
                gameField.placeCellInPrevCycle(cell)
            }
        }
        
        // redraw UI
        clientViewController.draw(with: gameField)
    }
    
    func onCellTapped(_ cellPos: (x:Int, y:Int)) {
        guard cellPos.x >= 0,
              cellPos.x < gameField.width,
              cellPos.y >= 0,
              cellPos.y < gameField.height
        else {
            return
        }
        
        let cell = Cell(pos: cellPos, userId: userId, color: color)
        if gameField.canPlaceCell(cell) {
            gameField.placeUnacceptedCell(cell)
            clientViewController.draw(with: gameField)
            client.send(message: .placeCell(gameCycle: cycle, cell: cell))
        }
    }
}

public extension UIColor {
    public static var random: UIColor {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1.0)
    }
}
