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
import UIKit
import MessageKit
import PromiseKit
import RxSwift

class ChatViewController: MessagesViewController {
    public func setupDependencies(navigator: SceneNavigatorProtocol, sessionManager: SessionManager, chatManager: ChatManager) {
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.chatManager = chatManager
        self.user = sessionManager.loggedInUserData
    }

    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    let refreshControl = UIRefreshControl()

    var navigator: SceneNavigatorProtocol!
    var sessionManager: SessionManager!
    var chatManager: ChatManager!

    var messages: [ChatViewMessage] = []
    var user: UserData!
    let disposeBag = DisposeBag()
}

extension ChatViewController {
    @IBAction func loadMoreMessages() {
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

    @IBAction func onLogout() {
        activityIndicatorView.isHidden = false
        self.messageInputBar.inputTextView.resignFirstResponder()

        firstly {
            self.sessionManager.logout(userName: self.user.userName)
        }.done { _ in
            ApplicationSettings.autologinEnabled = false
            self.navigator.navigate(to: .login)
        }.ensure(on: .main) {
            self.activityIndicatorView.isHidden = true
        }.catch { error in
            self.alert(error.localizedDescription)
        }
    }
}

extension ChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicatorView.isHidden = true

        messagesCollectionView.refreshControl = self.refreshControl
        refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)

        maintainPositionOnKeyboardFrameChanged = true // default false

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self

        assembleInteractions()

        self.chatManager.requestHIstory(fromId: nil, count: 10)
    }

    func assembleInteractions() {
        chatManager.onChatMessage
            .observeOn(MainScheduler.instance)
            .bind(to: self.onChatMessage)
            .disposed(by: disposeBag)

        // TODO: Move this to the chatManager?
        sessionManager.onLoginState
            .bind { [weak self] isLoggedIn in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.activityIndicatorView.isHidden = isLoggedIn
                }

                guard isLoggedIn else { return }

                firstly {
                    self.chatManager.requestHistory(fromId: self.messages.last?.id, count: nil)
                }.then(on: .main) {
                    self.updateViewWithHistory($0)
                }
            }.disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        view.bringSubviewToFront(activityIndicatorView)
        view.bringSubviewToFront(logoutButton)
    }
}

extension ChatViewController {
    private func updateViewWithMessage(_ message: ChatMessageData) {
        addMessage(message: message)
        messagesCollectionView.reloadData()

        if message.user.userName == user.userName || isLastSectionVisible() {
            messagesCollectionView.scrollToBottom(animated: true)
        } else {
            // TODO: show arrow button to scroll down or badge
        }
    }

    private func updateViewWithHistory(_ chatMessages: [ChatMessageData]) {
        let messagesWereEmpty = (messages.count == 0)
        chatMessages?.forEach(addMessage)

        if messagesWereEmpty {
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToBottom(animated: false)
        } else {
            refreshControl.endRefreshing()
            messagesCollectionView.reloadDataAndKeepOffset()
        }

        if self.messages.count == 0 || messages.first?.id == 0 {
            messagesCollectionView.refreshControl = nil
        }
    }

    private func addMessage(message: ChatV) {
        if let idx = messages.firstIndex(where: { $0.id >= message.id }) {
            if messages[idx].id != message.id {
                messages.insert(message, at: idx)
            }
        } else {
            messages.append(message)
        }
    }

    private func isLastSectionVisible() -> Bool {
        guard messages.isEmpty == false else { return false }
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
}

extension ChatViewController: MessagesDataSource {
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func currentSender() -> SenderType {
        return Sender(id: user.userName, displayName: user.userName)
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func messageTopLabelHeight(for message: MessageType,
                               at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 12
    }

    func messageTopLabelAttributedText(for message: MessageType,
                                       at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: message.sender.displayName,
                                  attributes: [.font: UIFont.systemFont(ofSize: 12)])
    }
}

extension ChatViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType,
                           at indexPath: IndexPath,
                           with maxWidth: CGFloat,
                           in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
}

extension ChatViewController: MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        let message = messages[indexPath.section]
        avatarView.backgroundColor = message.color.uiColor
    }
}

extension ChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        firstly {
            self.chatManager.send(messageText: text)
        }.map(on: .main) {
            self.messageInputBar.inputTextView.text = ""
        }.catch(on: .main) { _ in
            self.alert("Failed to send message")
        }
    }
}
