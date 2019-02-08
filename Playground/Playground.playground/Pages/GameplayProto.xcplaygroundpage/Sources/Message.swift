import Foundation

enum Message {
    case placeCell(gameCycle: Int, cell: Cell)
    case newCycle(gameCycle: Int)
}
