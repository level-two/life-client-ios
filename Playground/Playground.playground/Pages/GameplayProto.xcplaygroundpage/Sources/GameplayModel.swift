import Foundation

class GameplayModel {
    var width  = 16
    var height = 16
    var gameField: [Cell?]
    
    init() {
        gameField = [Cell?].init(repeating: nil, count: width*height)
    }
    
    func placeCell(cell: Cell) -> Bool {
        let (x, y) = cell.pos
        gameField[y*width+x] = cell
    }
    
    func canPlaceCell(cell: Cell) -> Bool {
        let (x, y) = cell.pos
        return gameField[y*width+x] == nil
    }
    
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
    // - - - 
    
    
    
    /*
    func addEvent(_ event: GameEvent) {
        switch event {
        case .update(let cycle):
            gameEvents.append(event)
            removeEvents(olderThan: cycle-2)
        case .placeCell(let placeEvent):
            
            if isCellOccupied(at: pos, cycle: event.cycle) {
                // skip this cell (at Server)
            }
            else if let idx = findUpdateEvent(for: placeEvent.cycle) {
                gameEvents.insert(event, at: idx)
            }
        }
    }
    
    func removeEvents(olderThan cycle: Int) {
        let updateEventIdx = gameEvents.firstIndex { ev in
            guard case .update(let updateCycle) = ev else { return false }
            return updateCycle == cycle
        }
        guard let _ = updateEventIdx else { return }
        gameEvents.removeSubrange(0..<updateEventIdx)
    }
    
    func isCellOccupied(at pos: (x: Int, y: Int), cycle: Int) -> Bool {
        return gameEvents.contains { ev in
            guard cycle == ev.cycle,
                case .placeCell(let x, let y) = ev.type,
                pos.x == x,
                pos.y == y
                else { return false }
            return true
        }
    }
    */

}
