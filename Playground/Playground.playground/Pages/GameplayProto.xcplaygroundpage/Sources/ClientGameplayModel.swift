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

public class ClientGameplayModel {
    weak var client: Client?
    weak var clientViewController: ClientViewController?
    
    let gameField = GameField()
    var cycle = 0
    
    public init(client: Client, clientViewController: ClientViewController) {
        self.client = client
        self.clientViewController = clientViewController
        client.onMessage.addObserver(self) { [weak self] message in self?.onMessage(message) }
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
                gameField.placeCell(cell)
            }
            else if gameCycle == cycle-1 {
                gameField.placeCellInPrevCycle(cell)
            }
        }
        
        // redraw UI
        clientViewController?.draw(with: gameField)
    }
}
