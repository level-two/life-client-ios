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
    init(_ navigator: SceneNavigatorProtocol, _ sessionManager: SessionManager, _ usersManager: UsersManager, _ chatManager: ChatManager, _ chatPresenter: ChatPresenter) {
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.usersManager = usersManager
        self.chatManager = chatManager
        self.chatPresenter = chatPresenter
        
        self.user = sessionManager.loggedInUserData
        chatPresenter.user = sessionManager.loggedInUserData
    }

    let navigator: SceneNavigatorProtocol
    let sessionManager: SessionManager
    let usersManager: UsersManager
    let chatManager: ChatManager
    
    let chatPresenter: ChatPresenter

    var messages: [ChatViewMessage] = []
    var user: UserData?
    let disposeBag = DisposeBag()
}

extension ChatInteractions {
    func assembleInteractions() {
        chatManager.onMessage.bind { message in
            firstly {
                self.usersManager.getUserData(for: message.userId)
            }.then { userData in
                let chatViewMessage = .init(with: message, and: userData)
                self.chatPresenter.addMessage(chatViewMessage)
            }
        }.disposed(by: disposeBag)
        
        /*
        sessionManager.onLoginState.bind { [weak self] isLoggedIn in
            guard let self = self else { return }

//                self.activityIndicatorView.isHidden = isLoggedIn

            guard isLoggedIn else { return }
            
            firstly {
                self.chatManager.requestHistory(fromId: self.messages.last?.id, count: nil)
            }.then {
                
            }
        }.disposed(by: disposeBag)
         */
        
        chatPresenter.onLoadMoreMessages.bind {
            guard let firstIndex = self.messages.first?.messageData.messageId else { return }
            assert(firstIndex > 0, "UIRefreshControl expected be hidden or disabled when we already received all messages")

            let count = firstIndex >= 10 ? 10 : firstIndex
            let fromId = firstIndex - count
            
            var chatMessageData: [ChatMessageData]?
            
            firstly {
                self.chatPresenter.startedHistoryRequest()
                return self.chatManager.requestHistory(fromId: fromId, count: count)
            }.then { messages in
                chatMessageData = messages
                let userIds = Array(Set(chatMessageData))
                return usersManager.getUserData(for: userIds)
            }.done { usersData in
                let chatViewMessages = chatMessageData.map { messageData
                    ChatViewMessage(messageData: messageData, userData: usersData.first { $0.userId == messageData.userId })
                }
                
                //self.messages.append(chatViewMessages)
                self.chatPresenter.addHistory(chatViewMessages)
            }.ensure(on: DispatchQueue.main) {
                self.chatPresenter.finishedHistoryRequest()
            }
        }.disposed(by: disposeBag)

        chatPresenter.onLogout.bind {
            //presenter.showActivityIndicator()

            firstly {
                self.sessionManager.logout(userName: self.user.userName)
            }.done { _ in
                ApplicationSettings.autologinEnabled = false
                self.navigator.navigate(to: .login)
            }.ensure(on: .main) {
                //presenter.hideActivityIndicator()
            }.catch { error in
                self.alert(error.localizedDescription)
            }
        }.disposed(by: disposeBag)
    }
}
