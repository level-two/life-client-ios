import Foundation

public class GameField {
    let width  = 16
    let height = 16
    
    public var acceptedCells: [Cell]
    public var unacceptedCells: [Cell]
    public var gameField: [Cell?]
    
    var prevUnacceptedCells: [Cell]
    var prevGameField: [Cell?]
    
    public init() {
        acceptedCells       = []
        unacceptedCells     = []
        prevUnacceptedCells = []
        gameField           = .init(repeating: nil, count: width*height)
        prevGameField       = .init(repeating: nil, count: width*height)
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
        // Discard unaccepted cells from the prev game cycle
        prevUnacceptedCells = []
        
        // Recalc current game field
        calcCurrentGameField()
        removeCurrentlyPlacedCellsIfConflicts()
        
        // Bake accepted cells to the game field
        acceptedCells.forEach { [unowned self] cell in
            self.gameField[cell.pos.y*width+cell.pos.x] = cell
        }
        
        // Move current unaccepted cells to previous
        prevUnacceptedCells = unacceptedCells
        
        // Move current game filed to the previous
        prevGameField = gameField
        
        // Clear current accepted and unaccepted cells
        acceptedCells = []
        unacceptedCells = []
        
        // Recalc current game field
        calcCurrentGameField()
    }
    
    public func canPlaceCell(_ cell: Cell) -> Bool {
        return gameField[cell.pos.y*width+cell.pos.x] == nil
            && acceptedCells.allSatisfy{$0.pos != cell.pos}
            && unacceptedCells.allSatisfy{$0.pos != cell.pos}
    }
    
    public func placeAcceptedCell(_ cell: Cell) {
        acceptedCells.append(cell)
        unacceptedCells.removeAll{$0.pos == cell.pos}
        prevUnacceptedCells.removeAll{$0.pos == cell.pos}
        
        // recalc game field
        calcCurrentGameField()
        
        // remove current unaccepded and accepted cells in case of conflict
        removeCurrentlyPlacedCellsIfConflicts()
    }
    
    public func placeUnacceptedCell(_ cell: Cell) {
        unacceptedCells.append(cell)
    }
    
    public func canPlaceCellInPrevCycle(_ cell: Cell) -> Bool {
        return prevGameField[cell.pos.y*width+cell.pos.x] == nil
            && prevUnacceptedCells.allSatisfy{$0.pos != cell.pos}
    }
    
    public func placeCellInPrevCycle(_ cell: Cell) {
        // remove from unaccepted if exists
        prevUnacceptedCells.removeAll { $0.pos == cell.pos }
        
        // place to prev game field
        self.prevGameField[cell.pos.y*width+cell.pos.x] = cell
        
        // recalc game field
        calcCurrentGameField()
        
        // remove current unaccepded cells in case of conflict
        removeCurrentlyPlacedCellsIfConflicts()
    }
    
    public func calcCurrentGameField() {
        // TODO: Add life
        gameField = prevGameField
        prevUnacceptedCells.forEach { [unowned self] cell in
            self.gameField[cell.pos.y*width+cell.pos.x] = cell
        }
    }
    
    public func removeCurrentlyPlacedCellsIfConflicts() {
        acceptedCells.removeAll { self.gameField[$0.pos.y*width+$0.pos.x] != nil }
        unacceptedCells.removeAll { self.gameField[$0.pos.y*width+$0.pos.x] != nil }
    }
}
