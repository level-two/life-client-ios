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

    init(_ networkManager: NetworkManager, _ sessionManager: SessionManager) {
        self.networkManager = networkManager
        self.sessionManager = sessionManager

        let fieldWidth = ApplicationSettings.fieldWidth
        let fieldHeight = ApplicationSettings.fieldHeight
        self.gameField = GameField(fieldWidth, fieldHeight)

        assembleInteractions()
    }

    public func place(_ cell: Cell) {
        guard gameField.canPlaceCell(cell) else { return }
        gameField.placeUnacceptedCell(cell)
        onPlaceCell.onNext(cell)
        let message = GameplayMessage.placeCell(cell: cell, gameCycle: self.cycle)
        _ = networkManager.send(message.json)
    }

    var cycle = 0
    var gameField: GameField
    let networkManager: NetworkManager
    let sessionManager: SessionManager
    let disposeBag = DisposeBag()
}

extension Gameplay {
    func assembleInteractions() {
        let decodedMessage = networkManager.onMessage
            .compactMap { try? GameplayMessage(from: $0) }

        decodedMessage
            .observeOn(MainScheduler.instance)
            .bind { [weak self] message in
                guard let self = self else { return }
                guard case .newGameCycle(let gameCycle) = message else { return }

                // TODO Handle case when game cycle is out of sync
                self.cycle = gameCycle
                self.gameField.updateForNewCycle()
                self.onNewCycle.onNext(self.cycle)
            }.disposed(by: disposeBag)

        decodedMessage
            .observeOn(MainScheduler.instance)
            .bind { [weak self] message in
                guard let self = self else { return }
                guard case .placeCell(let cell, let gameCycle) = message else { return }

                if gameCycle == self.cycle {
                    self.gameField.placeAcceptedCell(cell)
                    self.onPlaceCell.onNext(cell)
                } else if gameCycle == self.cycle-1 {
                    self.gameField.placeCellInPrevCycle(cell)
                    self.onPlaceCell.onNext(cell)
                }
            }.disposed(by: disposeBag)

        decodedMessage
            .observeOn(MainScheduler.instance)
            .bind { [weak self] message in
                guard let self = self else { return }
                guard case .gameField(let cells, let fieldWidth, let fieldHeight, let gameCycle) = message else { return }

                self.gameField = GameField(fieldWidth, fieldHeight, cells)
                self.cycle = gameCycle
                self.onNewCycle.onNext(self.cycle)
            }.disposed(by: disposeBag)

        self.sessionManager.onLoginState
            .observeOn(MainScheduler.instance)
            .bind { [weak self] isLoggedIn in
                guard isLoggedIn else { return }

                let message = GameplayMessage.requestGameField
                _ = self?.networkManager.send(message.json)
            }.disposed(by: disposeBag)
    }
}
