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

class GameplayInteractions {
    init(_ sceneNavigator: SceneNavigatorProtocol, _ sessionManager: SessionManager, _ gameplay: Gameplay, _ presenter: GameplayPresenter) {
        self.sceneNavigator = sceneNavigator
        self.sessionManager = sessionManager
        self.gameplay = gameplay
        self.presenter = presenter

        assembleInteractions()
    }

    private weak var presenter: GameplayPresenter!
    private var sceneNavigator: SceneNavigatorProtocol
    private var sessionManager: SessionManager
    private var gameplay: Gameplay
    private let disposeBag = DisposeBag()
}

extension GameplayInteractions {
    private func assembleInteractions() {
        self.gameplay.onNewCycle
            .observeOn(MainScheduler.instance)
            .bind { [weak self] _ in
                guard let self = self else { return }
                self.presenter.drawGameField(self.gameplay.gameField)
            }.disposed(by: disposeBag)

        // TODO: Send color instead of userId + reduce color to just one byte value
    }
}
