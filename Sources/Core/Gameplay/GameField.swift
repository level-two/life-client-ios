// -----------------------------------------------------------------------------
//    Copyright (C) 2019 Yauheni Lychkouski.
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

class GameField {
    let width: Int
    let height: Int

    var cells: [Cell] {
        return gameField.allCells + acceptedCells + unacceptedCells
    }

    init(_ width: Int, _ height: Int, _ cells: [Cell] = []) {
        self.width               = width
        self.height              = height
        self.acceptedCells       = []
        self.unacceptedCells     = []
        self.prevUnacceptedCells = []
        self.gameField           = GameFieldArray(width, height)
        self.prevGameField       = GameFieldArray(width, height)

        cells.forEach(gameField.put)
    }

    func updateForNewCycle() {
        // Discard unaccepted cells from the prev game cycle
        prevUnacceptedCells = []

        // Recalc current game field
        calcCurrentGameField()
        removeCurrentlyPlacedCellsIfConflicts()

        // Bake accepted cells to the game field
        acceptedCells.forEach(gameField.put)

        // Move current unaccepted cells to previous
        prevUnacceptedCells = unacceptedCells

        // Move current game filed to the previous
        prevGameField = gameField

        // Clear current accepted and unaccepted cells
        acceptedCells   = []
        unacceptedCells = []

        // Recalc current game field
        calcCurrentGameField()
    }

    func canPlaceCell(_ cell: Cell) -> Bool {
        return gameField.isEmpty(at: cell.pos)
            && acceptedCells.allSatisfy {$0.pos != cell.pos}
            && unacceptedCells.allSatisfy {$0.pos != cell.pos}
    }

    func placeAcceptedCell(_ cell: Cell) {
        acceptedCells.append(cell)
        unacceptedCells.removeAll {$0.pos == cell.pos}
        prevUnacceptedCells.removeAll {$0.pos == cell.pos}

        // recalc game field
        calcCurrentGameField()

        // remove current unaccepded and accepted cells in case of conflict
        removeCurrentlyPlacedCellsIfConflicts()
    }

    func placeUnacceptedCell(_ cell: Cell) {
        unacceptedCells.append(cell)
    }

    func canPlaceCellInPrevCycle(_ cell: Cell) -> Bool {
        return prevGameField.isEmpty(at: cell.pos)
            && prevUnacceptedCells.allSatisfy {$0.pos != cell.pos}
    }

    func placeCellInPrevCycle(_ cell: Cell) {
        // remove from unaccepted if exists
        prevUnacceptedCells.removeAll { $0.pos == cell.pos }

        // place to prev game field
        prevGameField.put(cell)

        // recalc game field
        calcCurrentGameField()

        // remove current unaccepded cells in case of conflict
        removeCurrentlyPlacedCellsIfConflicts()
    }

    func calcCurrentGameField() {
        gameField = GameFieldArray(with: prevGameField)
        prevUnacceptedCells.forEach(gameField.put)

        // TODO: Add life
        func getNeighbors(_ x: Int, _ y: Int) -> [Cell] {
            return [
                gameField[x-1, y-1],
                gameField[x-1, y  ],
                gameField[x-1, y+1],
                gameField[x, y-1],
                gameField[x, y+1],
                gameField[x+1, y-1],
                gameField[x+1, y  ],
                gameField[x+1, y+1]
                ].compactMap {$0}
        }

        var cellsToPut = [Cell]()
        var cellsToRemove = [Cell]()

        for x in 0..<gameField.width {
            for y in 0..<gameField.height {
                let neighbors = getNeighbors(x, y)
                let cell = gameField[x, y]

                // give birth if there are min two cells of the same user
                if cell == nil && neighbors.count == 3 {
                    let midCell = neighbors.sorted {$0.color.hashValue < $1.color.hashValue}[1]
                    if (neighbors.filter {$0.color.hashValue == midCell.color.hashValue}).count >= 2 {
                        let newCell = Cell(pos: (x:x, y:y), color: midCell.color)
                        cellsToPut.append(newCell)
                    }
                }

                // death
                if cell != nil && (neighbors.count < 2 || neighbors.count > 3) {
                    cellsToRemove.append(cell!)
                }
            }
        }

        cellsToPut.forEach(gameField.put)
        cellsToRemove.forEach {gameField[$0.pos] = nil}
    }

    func removeCurrentlyPlacedCellsIfConflicts() {
        acceptedCells.removeAll { self.gameField.isEmpty(at: $0.pos) == false }
        unacceptedCells.removeAll { self.gameField.isEmpty(at: $0.pos) == false }
    }

    private var acceptedCells: [Cell]
    private var unacceptedCells: [Cell]
    private var gameField: GameFieldArray

    private var prevUnacceptedCells: [Cell]
    private var prevGameField: GameFieldArray
}
