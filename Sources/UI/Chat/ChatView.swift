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
    
    override func viewWillAppear(_ animated: Bool) {
        view.bringSubviewToFront(activityIndicatorView)
        view.bringSubviewToFront(logoutButton)
    }
}

extension ChatViewController {
    func chatViewData() {
        firstly {
            chatManager.requestHistory()
            }.map {
                $0.compactMap { ChatViewData($0.userId, $0.messageId) }
            }.then {
                uniqueUserIds = $0.uniqueValues { $0.userId }
                usersManager.getUsersData(for:)
            }.then {
                // fill messages with user data
        }
        
    }
    
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
