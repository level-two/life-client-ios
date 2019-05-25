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
import RxGesture

class GameplayPresenter {
    let onTap = PublishSubject<(x: Int, y: Int)>()

    init(_ gameplayViewController: GameplayViewController) {
        self.gameplayViewController = gameplayViewController

        gameplayViewController.rx.viewDidLoad.bind { [weak self] in
            self?.assembleInteractions()
        }.disposed(by: disposeBag)
    }

    func drawGameField(_ gameField: GameField) {
        let viewData = GameFieldViewData(cells: gameField.cells,
                                         fieldWidth: gameField.width,
                                         fieldHeight: gameField.height)
        gameplayViewController.drawGameField(with: viewData)
    }

    private weak var gameplayViewController: GameplayViewController!
    private let disposeBag = DisposeBag()
}

extension GameplayPresenter {
    private func assembleInteractions() {
        gameplayViewController.gameFieldView.rx
            .tapGesture(configuration: { _, delegate in
                delegate.otherFailureRequirementPolicy = .custom { _, otherGestureRecognizer in
                    if let gesture = otherGestureRecognizer as? UITapGestureRecognizer, gesture.numberOfTapsRequired == 2 {
                        return true
                    }
                    return false
                }
            })
            .when(.recognized)
            .bind { [weak self] gesture in
                guard let self = self else { return }
                guard self.gameplayViewController.isZoomed else { return }
                guard let view = gesture.view else { return }

                let point = gesture.location(in: view)
                let fieldViewSize = min(view.bounds.width, view.bounds.height)

                let posX = Int(point.x / fieldViewSize * CGFloat(self.gameplayViewController.fieldWidth))
                let posY = Int(point.y / fieldViewSize * CGFloat(self.gameplayViewController.fieldHeight))

                self.onTap.onNext((x: posX, y: posY))
            }.disposed(by: disposeBag)

        gameplayViewController.gameFieldView.rx
            .tapGesture(configuration: { recognizer, _ in recognizer.numberOfTapsRequired = 2 })
            .when(.recognized)
            .bind { [weak self] gesture in
                guard let self = self else { return }

                if self.gameplayViewController.isZoomed {
                    self.gameplayViewController.zoomOut()
                } else {
                    let point = gesture.location(in: gesture.view)
                    self.gameplayViewController.zoomIn(to: point)
                }
            }.disposed(by: disposeBag)
    }
}
