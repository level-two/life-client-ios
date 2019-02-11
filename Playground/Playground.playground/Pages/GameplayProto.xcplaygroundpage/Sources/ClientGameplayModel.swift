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

class ClientGameplayModel {
    // TODO:
    // - Add update timer. On update:
    // - - Increment current cycle
    // - - Send broadcast message
    // - - Update game field
    // - - Remove old events and gamefield state (cycle-2)
    //
    // - Receive messages from players
    // - - For current cycle:
    // - - - Check if cell is free then place new cell
    // - - For previous cycle:
    // - - - Check if cell is free at that cycle
    // - - - Place cell
    // - - - Recalc field for the next cycle
    // - - - For all new cells in the next move
    // - - - - if it appears that their field is occupied after update - remove them
    // - - For older cycles - just ignore them - they are outdated
    
    let updatePeriod: TimeInterval = 5.0
    
    weak var client: Client?
    let gameField = GameField()
    var cycle = 0
    
    init(client: Client) {
        self.client = client
        client.onMessage.addObserver(self) { [weak self] message in self?.onMessage(message) }
    }
    
    /// On update:
    /// - Increment current cycle
    /// - Send broadcast message
    /// - Update game field
    /// - Remove old events and gamefield state (cycle-2)
    func update() {
        
        // redraw UI
    }
    
    /// Receive messages from players
    /// - For current cycle:
    /// - - Check if cell is free then place new cell
    /// - For previous cycle:
    /// - - Check if cell is free at that cycle
    /// - - Place cell
    /// - - Recalc field for the next cycle
    /// - - For all new cells in the next move
    /// - - - if it appears that their field is occupied after update - remove them
    /// - For older cycles - just ignore them - they are outdated
    func onMessage(_ message: Message) {
        if case .new(let gameCycle) = message {
            // TODO: Handle connection loss - when several updates had been missed
            cycle = gameCycle
            gameField.updateForNewCycle()
        }
        
        if case .placeCell(let gameCycle, let cell) = message {
            if gameCycle == cycle && gameField.canPlaceCell(cell) == true {
                gameField.placeCell(cell)
                client?.send(message: .placeCell(gameCycle: cycle, cell: cell))
            }
            else if gameCycle == cycle-1 && gameField.canPlaceCellInPrevCycle(cell) {
                gameField.placeCellInPrevCycle(cell)
                client?.send(message: .placeCell(gameCycle: cycle-1, cell: cell))
            }
        }
        // redraw UI
    }
}
