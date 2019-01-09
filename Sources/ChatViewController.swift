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

extension ChatMessage: MessageType {
    var messageId: String {
        return String(id)
    }
    
    var sender: Sender {
        return Sender(id: user.userName, displayName: user.userName)
    }
    
    // TODO
    var sentDate: Date {
        return Date()
    }
    
    var kind: MessageKind {
        return .text(message)
    }
}

extension ChatMessage {
    static var dummy: ChatMessage {
        return ChatMessage(user: User(userName:"", userId:0, color:[0.0, 0.0, 0.0, 0.0]), message:"", id:0)
    }
}

class ChatViewController: MessagesViewController {
    private var navigator: LoginNavigator!
    private var sessionManager: SessionManager!
    private var networkManager: NetworkManager!
    private var networkMessages: NetworkMessages!
    
    var messages: [ChatMessage] = []
    var user: User!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupDependencies(navigator: LoginNavigator, sessionManager: SessionManager, networkManager: NetworkManager, networkMessages: NetworkMessages) {
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.networkManager = networkManager
        self.networkMessages = networkMessages
        self.user = sessionManager.user.require()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        self.networkMessages.chatMessage.addHandler(target: self, handler: ChatViewController.onChatMessage)
        self.networkMessages.chatMessagesResponse.addHandler(target: self, handler: ChatViewController.onChatMessagesResponse)
        
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        self.networkMessages.send(message: GetRecentChatMessages())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.networkMessages.chatMessage.removeTarget(self)
        self.networkMessages.chatMessagesResponse.removeTarget(self)
    }
    
    private func onChatMessage(message: ChatMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.addMessage(message: message)
            self?.messagesCollectionView.reloadData()
        }
    }
    
    private func onChatMessagesResponse(response: ChatMessagesResponse) {
        DispatchQueue.main.async { [weak self] in
            guard let chatHistory = response.chatHistory else { return }
            for message in chatHistory {
                self?.addMessage(message: message)
            }
            self?.messagesCollectionView.reloadDataAndKeepOffset()
        }
    }
    
    private func addMessage(message: ChatMessage) {
        if let idx = messages.firstIndex(where: { $0.id >= message.id }) {
            if messages[idx].id != message.id {
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
        let color = message.user.color
        avatarView.backgroundColor = UIColor(withRgbComponents: color)
    }
}

extension ChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        self.networkMessages.send(message: SendChatMessage(message: text)).observe { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .error:
                    self?.alert("Failed to send message")
                case .value:
                    inputBar.inputTextView.text = ""
                    self?.messagesCollectionView.scrollToBottom(animated: true)
                }
            }
        }
    }
}
