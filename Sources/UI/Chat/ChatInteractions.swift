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
    init(_ navigator: SceneNavigatorProtocol, _ sessionManager: SessionManager,
         _ usersManager: UsersManager, _ chatManager: ChatManager, _ chatPresenter: ChatPresenter) {

        self.navigator = navigator
        self.sessionManager = sessionManager
        self.usersManager = usersManager
        self.chatManager = chatManager
        self.chatPresenter = chatPresenter

        self.user = sessionManager.loggedInUserData!

        assembleInteractions()
    }

    weak var chatPresenter: ChatPresenter!
    let navigator: SceneNavigatorProtocol
    let sessionManager: SessionManager
    let usersManager: UsersManager
    let chatManager: ChatManager

    var user: UserData
    let disposeBag = DisposeBag()
}

extension ChatInteractions {
    func assembleInteractions() {
        chatManager.onMessage
            .observeOn(MainScheduler.instance)
            .bind { [weak self] message in
                guard let self = self else { return }

                self.chatPresenter.addMessage(message)

                firstly {
                    self.usersManager.userData(for: message.userId)
                }.done(on: .main) { userData in
                    self.chatPresenter.updateViewData(for: message.messageId, with: userData)
                }.catch { error in
                    print("Error: \(error)")
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

        chatPresenter.onMessageSend.bind { [weak self] text in
            _ = self?.chatManager.send(messageText: text)
        }.disposed(by: disposeBag)

        chatPresenter.onViewWillAppear.bind { _ in
            self.chatPresenter.startedHistoryRequest()

            firstly {
                self.chatManager.requestRecentHistory()
            }.done(on: .main) { messages in
                self.chatPresenter.addHistory(messages)

                messages.map { $0.userId }.unique.forEach { userId in
                    firstly {
                        self.usersManager.userData(for: userId)
                    }.done(on: .main) { userData in
                        messages.filter { $0.userId == userId }.forEach { message in
                            self.chatPresenter.updateViewData(for: message.messageId, with: userData)
                        }
                    }.catch { error in
                        print(error)
                    }
                }
            }.ensure(on: .main) {
                self.chatPresenter.finishedHistoryRequest()
            }.catch { error in
                print(error)
            }
        }.disposed(by: disposeBag)

        chatPresenter.onLoadMoreMessages
            .observeOn(MainScheduler.instance)
            .bind { fromId, count in
                self.chatPresenter.startedHistoryRequest()

                firstly {
                    self.chatManager.requestHistory(fromId: fromId, count: count)
                }.done(on: .main) { messages in
                    self.chatPresenter.addHistory(messages)

                    messages.map { $0.userId }.unique.forEach { userId in
                        firstly {
                            self.usersManager.userData(for: userId)
                        }.done(on: .main) { userData in
                            messages.filter { $0.userId == userId }.forEach { message in
                                self.chatPresenter.updateViewData(for: message.messageId, with: userData)
                            }
                        }.catch { error in
                            print(error)
                        }
                    }
                }.ensure(on: .main) {
                    self.chatPresenter.finishedHistoryRequest()
                }.catch { error in
                    print(error)
                }
            }.disposed(by: disposeBag)

        chatPresenter.onLogout.bind {
            //self.chatPresenter.showActivityIndicator()

            firstly {
                self.sessionManager.logout(userName: self.user.userName)
            }.done { _ in
                ApplicationSettings.autologinEnabled = false
                self.navigator.navigate(to: .login)
            }.catch { error in
                //self.alert(error.localizedDescription)
                print(error)
            }
        }.disposed(by: disposeBag)
    }
}
