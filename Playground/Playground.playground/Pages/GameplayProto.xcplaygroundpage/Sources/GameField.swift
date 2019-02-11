import Foundation

class GameField {
    let width  = 16
    let height = 16
    
    var gameField: [Cell?]
    var placedCells: [Cell]
    
    var prevGameField: [Cell?]
    var prevPlacedCells: [Cell]
    
    init() {
        placedCells     = []
        prevPlacedCells = []
        gameField       = .init(repeating: nil, count: width*height)
        prevGameField   = .init(repeating: nil, count: width*height)
    }
    
    /*
    init(with cells: [Cell], cycle: Int) {
        placeCells     = []
        prevPlaceCells = []
        gameField     = .init(repeating: nil, count: width*height)
        prevGameField = .init(repeating: nil, count: width*height)
        cells.forEach(placeCell)
    }
    */
    
    func updateForNewCycle() {
        prevPlacedCells = placedCells
        placedCells     = []
        prevGameField   = gameField
        calcCurrentGameField()
    }
    
    func canPlaceCell(_ cell: Cell) -> Bool {
        let (x, y) = cell.pos
        return gameField[y*width+x] == nil
    }
    
    func placeCell(_ cell: Cell) {
        placedCells.append(cell)
    }
    
    func canPlaceCellInPrevCycle(_ cell: Cell) -> Bool {
        let (x, y) = cell.pos
        return prevGameField[y*width+x] == nil
    }
    
    func placeCellInPrevCycle(_ cell: Cell) {
        prevPlacedCells.append(cell)
        calcCurrentGameField()
        removeCurrentlyPlacedCellsIfConflicts()
    }
    
    func updateGameFieldForNewCycle() {
        prevGameField = gameField
        calcCurrentGameField()
    }
    
    func calcCurrentGameField() {
        // TODO: Add life
        gameField = prevGameField
        prevPlacedCells.forEach { [unowned self] cell in
            let (x, y) = cell.pos
            self.gameField[y*width+x] = cell
        }
    }
    
    func removeCurrentlyPlacedCellsIfConflicts() {
        placedCells = placedCells.filter(canPlaceCell)
    }
}
