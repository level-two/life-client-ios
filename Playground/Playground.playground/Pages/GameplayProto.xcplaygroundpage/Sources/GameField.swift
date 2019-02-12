import Foundation

public class GameField {
    let width  = 16
    let height = 16
    
    public var gameField: [Cell?]
    public var placedCells: [Cell]
    
    var prevGameField: [Cell?]
    var prevPlacedCells: [Cell]
    
    public init() {
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
    
    public func updateForNewCycle() {
        prevPlacedCells = placedCells
        placedCells     = []
        prevGameField   = gameField
        calcCurrentGameField()
    }
    
    public func canPlaceCell(_ cell: Cell) -> Bool {
        let (x, y) = cell.pos
        return gameField[y*width+x] == nil && placedCells.allSatisfy{$0.pos != cell.pos}
    }
    
    public func placeCell(_ cell: Cell) {
        placedCells.append(cell)
    }
    
    public func canPlaceCellInPrevCycle(_ cell: Cell) -> Bool {
        let (x, y) = cell.pos
        return prevGameField[y*width+x] == nil && prevPlacedCells.allSatisfy{$0.pos != cell.pos}
    }
    
    public func placeCellInPrevCycle(_ cell: Cell) {
        prevPlacedCells.append(cell)
        calcCurrentGameField()
        removeCurrentlyPlacedCellsIfConflicts()
    }
    
    public func updateGameFieldForNewCycle() {
        prevGameField = gameField
        calcCurrentGameField()
    }
    
    public func calcCurrentGameField() {
        // TODO: Add life
        gameField = prevGameField
        prevPlacedCells.forEach { [unowned self] cell in
            let (x, y) = cell.pos
            self.gameField[y*width+x] = cell
        }
    }
    
    public func removeCurrentlyPlacedCellsIfConflicts() {
        placedCells = placedCells.filter(canPlaceCell)
    }
}
