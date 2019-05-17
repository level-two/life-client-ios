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
import RxCocoa

class ChatPresenter {
    public let onSendButton = PublishSubject<String>()

    public var inputBarText: String {
        get {
            return chatViewController.messageInputBar.inputTextView.text
        }
        set {
            chatViewController.messageInputBar.inputTextView.text = newValue
        }
    }

    init(_ chatViewController: ChatViewController, _ currentUser: UserData) {
        self.chatViewController = chatViewController
        self.user = currentUser

        chatViewController.onSendButton.bind(to: onSendButton).disposed(by: disposeBag)
    }

    public func addMessage(_ message: ChatViewMessage) {
        chatViewController.add(newMessages: message)

        if message.userName == user.userName || chatViewController.isLastSectionVisible {
            chatViewController.reloadDataScrollingToBottom(animated: true)
        } else {
            chatViewController.reloadDataKeepingOffset()
        }
    }

    public func addHistory(_ messages: [ChatViewMessage]) {
        let messagesWereEmpty = chatViewController.numberOfMessages == 0

        chatViewController.add(newMessages: messages)

        if messagesWereEmpty {
            chatViewController.reloadDataScrollingToBottom(animated: false)
        } else {
            chatViewController.reloadDataKeepingOffset()
            chatViewController.endRefreshing()
        }

        if messages.contains(where: {$0.id == 0}) {
            chatViewController.disableRefreshControl()
        }
    }

    fileprivate weak var chatViewController: ChatViewController!
    fileprivate let user: UserData
    fileprivate let disposeBag = DisposeBag()
}
