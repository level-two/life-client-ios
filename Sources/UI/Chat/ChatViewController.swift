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
import RxSwift

class ChatViewController: MessagesViewController {
    public let onSendButton = PublishSubject<String>()
    public let onLoadMoreMessages = PublishSubject<Void>()
    public let onLogout = PublishSubject<Void>()

    override func viewDidLoad() {
        super.viewDidLoad()

        maintainPositionOnKeyboardFrameChanged = true // default false
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self

        refreshControl.rx.controlEvent(.valueChanged).bind(to: onLoadMoreMessages).disposed(by: disposeBag)
        logoutButton.rx.tap.bind(to: onLogout).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        view.bringSubviewToFront(logoutButton)
    }

    public func enableRefreshControl() {
        messagesCollectionView.refreshControl = self.refreshControl
    }

    public func disableRefreshControl() {
        messagesCollectionView.refreshControl = nil
    }

    public func beginRefreshing() {
        refreshControl.beginRefreshing()
    }

    public func endRefreshing() {
        refreshControl.endRefreshing()
    }

    public func setUser(_ user: UserData) {
        self.user = user
    }

    public func add(newMessages: ChatViewMessage...) {
        newMessages.forEach { messages[$0.id] = $0 }
    }

    public func add(newMessages: [ChatViewMessage]) {
        newMessages.forEach { messages[$0.id] = $0 }
    }

    public func reloadDataKeepingOffset() {
        messagesCollectionView.reloadDataAndKeepOffset()
    }

    public func reloadDataScrollingToBottom(animated: Bool = false) {
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: animated)
    }

    public var numberOfMessages: Int {
        return messages.count
    }

    public var isLastSectionVisible: Bool {
        guard messages.isEmpty == false else { return false }
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

    @IBOutlet weak var logoutButton: UIButton!
    let refreshControl = UIRefreshControl()

    var user: UserData!
    var messages: [Int: ChatViewMessage] = [:]
    var disposeBag = DisposeBag()
}

extension ChatViewController: MessagesDataSource {
    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    public func currentSender() -> SenderType {
        return Sender(id: user.userName, displayName: user.userName)
    }

    public func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return Array(messages)[indexPath.section].value
    }

    public func messageTopLabelHeight(for message: MessageType,
                               at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 12
    }

    public func messageTopLabelAttributedText(for message: MessageType,
                                       at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: message.sender.displayName,
                                  attributes: [.font: UIFont.systemFont(ofSize: 12)])
    }
}

extension ChatViewController: MessagesLayoutDelegate {
    public func heightForLocation(message: MessageType,
                           at indexPath: IndexPath,
                           with maxWidth: CGFloat,
                           in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
}

extension ChatViewController: MessagesDisplayDelegate {
    public func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        let message = Array(messages)[indexPath.section].value
        avatarView.backgroundColor = message.color.uiColor
    }
}

extension ChatViewController: MessageInputBarDelegate {
    public func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        onSendButton.onNext(text)
    }
}
