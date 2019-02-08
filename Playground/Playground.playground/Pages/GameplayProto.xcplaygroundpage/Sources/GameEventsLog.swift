import Foundation

class GameEventsLog {
    var gameEvents = [Int: [Cell]]()
    
    func newCycle(cycle: Int) {
        gameEvents[cycle] = []
    }
    
    func removeCells(for oldCycle: Int) {
        assert(gameEvents.allSatisfy { (key, _) in key >= oldCycle } )
        gameEvents.removeValue(forKey: oldCycle)
    }
    
    func getCells(for cycle: Int) -> [Cell] {
        assert(gameEvents.contains { (key, _) in key == cycle })
        return gameEvents[cycle]!
    }
    
    func place(cell: Cell, for cycle: Int) {
        assert(gameEvents.contains { (key, _) in key == cycle })
        gameEvents[cycle]!.append(cell)
    }
    
    func remove(cell: Cell, for cycle: Int) {
        assert(gameEvents.contains { (key, _) in key == cycle })
        gameEvents[cycle]!.removeAll { $0 == cell }
    }
}
