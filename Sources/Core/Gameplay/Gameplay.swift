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
import RxSwift
import RxCocoa

class Gameplay {
    public let onNewCycle = PublishSubject<Int>()
    public let onPlaceCell = PublishSubject<Cell>()

    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager

        let fieldWidth = ApplicationSettings.fieldWidth
        let fieldHeight = ApplicationSettings.fieldHeight
        self.gameField = GameField(fieldWidth, fieldHeight)

        assembleInteractions()
    }

    public func place(_ cell: Cell) -> Bool {
        guard gameField.canPlaceCell(cell) else { return }
        gameField.placeUnacceptedCell(cell)
        onPlaceCell.onNext(cell)
        networkManager.send(GameplayMessage.placeCell(gameCycle: self.cycle, cell: cell))
    }

    var cycle = 0
    let gameField: GameField
    let networkManager: NetworkManager
    let disposeBag = DisposeBag()
}

extension Gameplay {
    func assembleInteractions() {
        networkManager.onMessage.bind { [weak self] message in
            guard let self = self else { return }
            guard case GameplayMessage.newGameCycle(let gameCycle) = message else { return }

            // TODO Handle case when game cycle is out of sync
            self.cycle = gameCycle
            self.gameField.updateForNewCycle()
            self.onNewCycle.onNext(self.cycle)
        }.disposed(by: disposeBag)

        networkManager.onMessage.bind { [weak self] message in
            guard let self = self else { return }
            guard case GameplayMessage.placeCell(let gameCycle, let cell) = message else { return }

            if gameCycle == cycle {
                self.gameField.placeAcceptedCell(cell)
                self.onPlaceCell.onNext(cell)
            } else if gameCycle == cycle-1 {
                self.gameField.placeCellInPrevCycle(cell)
                self.onPlaceCell.onNext(cell)
            }
        }.disposed(by: disposeBag)
    }
}
