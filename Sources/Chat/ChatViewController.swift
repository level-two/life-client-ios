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
        return ChatMessage(user: User(userName:"", userId:0, color:.black), message:"", id:0)
    }
}

class ChatViewController: MessagesViewController {
    private let autologinUserNameKey = "autologinUserNameKey"
    
    private var navigator: SceneNavigator!
    private var sessionManager: SessionManager!
    private var networkManager: NetworkManager!
    private var networkMessages: NetworkMessages!
    
    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    private let refreshControl = UIRefreshControl()
    
    var messages: [ChatMessage] = []
    var user: User!
    
    func setupDependencies(navigator: SceneNavigator, sessionManager: SessionManager, networkManager: NetworkManager, networkMessages: NetworkMessages) {
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.networkManager = networkManager
        self.networkMessages = networkMessages
        self.user = sessionManager.user.require()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorView.isHidden = true
        
        messagesCollectionView.refreshControl = self.refreshControl
        refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        self.networkMessages.chatMessage.addHandler(target: self, handler: ChatViewController.onChatMessage)
        self.networkMessages.chatMessagesResponse.addHandler(target: self, handler: ChatViewController.onChatMessagesResponse)
        self.sessionManager.loginStateEvent.addHandler(target: self, handler: ChatViewController.onLoginStateChanged)
        self.networkMessages.send(message: GetRecentChatMessages())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.bringSubviewToFront(activityIndicatorView)
        view.bringSubviewToFront(logoutButton)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.networkMessages.chatMessage.removeTarget(self)
        self.networkMessages.chatMessagesResponse.removeTarget(self)
        self.sessionManager.loginStateEvent.removeTarget(self)
    }
    
    func onLoginStateChanged(isLogged: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicatorView.isHidden = isLogged
        }
        
        if isLogged {
            self.networkMessages.send(message: GetRecentChatMessages(fromId: messages.last?.id))
        }
    }
    
    @IBAction func loadMoreMessages() {
        let firstIndex = messages.first.require().id
        guard firstIndex > 0 else {
            preconditionFailure("UIRefreshControl expected be hidden or disabled when we already received all messages")
        }
        
        let count = firstIndex >= 10 ? 10 : firstIndex
        let fromId = firstIndex - count
        
        self.networkMessages.send(message: GetChatMessages(fromId: fromId, count: count))
    }
    
    private func onChatMessage(message: ChatMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let isLastSectionVisible = self.isLastSectionVisible()
            
            self.addMessage(message: message)
            self.messagesCollectionView.reloadData()
            
            if message.user.userName == self.user.userName || isLastSectionVisible {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
            else {
                // show arrow button to scroll down
                // or badge
            }
        }
    }
    
    private func onChatMessagesResponse(response: ChatMessagesResponse) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let chatHistory = response.chatHistory else { return }
            
            let messagesWereEmpty = (self.messages.count == 0)
            
            for message in chatHistory {
                self.addMessage(message: message)
            }
            
            if messagesWereEmpty {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: false)
            }
            else {
                self.refreshControl.endRefreshing()
                self.messagesCollectionView.reloadDataAndKeepOffset()
            }
            
            if self.messages.count == 0 || self.messages.first?.id == 0 {
                self.messagesCollectionView.refreshControl = nil
            }
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
        avatarView.backgroundColor = message.user.color
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
                }
            }
        }
    }
}

extension ChatViewController {
    @IBAction func onLogout() {
        activityIndicatorView.isHidden = false
        self.messageInputBar.inputTextView.resignFirstResponder()
        
        sessionManager.logout(userName: user.userName).observe { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicatorView.isHidden = true
            }
            
            switch result {
            case .value:
                UserDefaults.standard.set(nil, forKey: self.autologinUserNameKey)
                self.navigator.navigate(to: .login)
            case .error(let error):
                self.alert(error.localizedDescription)
            }
        }
    }
}
