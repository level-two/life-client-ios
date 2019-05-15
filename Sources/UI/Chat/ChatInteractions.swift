// -----------------------------------------------------------------------------
//    Copyright (C) 2018 Yauheni Lychkouski.
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
import MessageKit
import PromiseKit
import RxSwift

class ChatInteractions {
    init(_ navigator: SceneNavigatorProtocol, _ sessionManager: SessionManager, _ chatManager: ChatManager) {
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.chatManager = chatManager
        self.user = sessionManager.loggedInUserData
    }
    
    var navigator: SceneNavigatorProtocol
    var sessionManager: SessionManager
    var chatManager: ChatManager
    
    var messages: [ChatViewMessage] = []
    var user: UserData?
    let disposeBag = DisposeBag()
}

extension ChatInteractions {
    func assembleInteractions() {
        chatManager.onChatMessage
            .observeOn(MainScheduler.instance)
            .bind(to: self.onChatMessage)
            .disposed(by: disposeBag)
        
        sessionManager.onLoginState
            .bind { [weak self] isLoggedIn in
                guard let self = self else { return }
                
//                self.activityIndicatorView.isHidden = isLoggedIn
                
                guard isLoggedIn else { return }
                
                firstly {
                    self.chatManager.requestHistory(fromId: self.messages.last?.id, count: nil)
                }.then(on: .main) {
                    self.updateViewWithHistory($0)
                }
            }.disposed(by: disposeBag)
        
        
        presenter.onLoadMoreMessages.bind {
            guard let firstIndex = messages.first?.id else { return }
            assert(firstIndex > 0, "UIRefreshControl expected be hidden or disabled when we already received all messages")
            
            let count = firstIndex >= 10 ? 10 : firstIndex
            let fromId = firstIndex - count
            
            firstly {
                self.chatManager.requestHistory(fromId: self.messages.last?.id, count: nil)
            }.then(on: .main) {
                self.updateViewWithHistory($0)
            }
        }
        
        presenter.onLogout.bind {
            presenter.showActivityIndicator()
            
            firstly {
                self.sessionManager.logout(userName: self.user.userName)
            }.done { _ in
                ApplicationSettings.autologinEnabled = false
                self.navigator.navigate(to: .login)
            }.ensure(on: .main) {
                presenter.hideActivityIndicator()
            }.catch { error in
                self.alert(error.localizedDescription)
            }
        }
    }
}
