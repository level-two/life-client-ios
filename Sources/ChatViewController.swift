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

import UIKit
import MessageKit
import MessageInputBar

class ChatViewController: MessagesViewController {
    private var navigator: LoginNavigator!
    private var sessionManager: SessionManager!
    
    var messages: [ChatMessage] = []
    var user: User!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupDependencies(navigator: LoginNavigator, sessionManager: SessionManager) {
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.user = sessionManager.user.require()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        sessionManager.sendSessionMessage(["recentMessagesRequest"])
        //sessionManager.messagesHandler = { [weak self] message in
        //    guard let self = self else { return }
        //    self.tryProcessMessage(message)
        //}
    }
    
    //private func tryProcessMessage(_ message: )
    
    private func addMessage(message: ChatMessage) {
        if let idx = messages.firstIndex(where: { $0.messageIntId >= message.messageIntId }) {
            if messages[idx].messageIntId != message.messageIntId {
                messages.insert(message, at: idx)
            }
        }
        else {
            messages.append(message)
        }
    }
}

extension ChatViewController: MessagesDataSource {
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func currentSender() -> Sender {
        return Sender(id: user.userName, displayName: user.userName)
    }
    
    func messageForItem(at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> MessageType {
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
        //let color = message.user.color
        //avatarView.backgroundColor = UIColor(withRgbComponents: color)
    }
}

extension ChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let newMessage = ChatMessage(userName: user.userName, message: text, messageIntId: 0)
        //messages.append(newMessage)
        //inputBar.inputTextView.text = ""
        //messagesCollectionView.reloadData()
        //messagesCollectionView.scrollToBottom(animated: true)
        sessionManager.sendSessionMessage(newMessage.toDictionary)
    }
}
