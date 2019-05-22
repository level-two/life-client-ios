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
import RxSwift

class ChatPresenter {
    public let onMessageSend = PublishSubject<String>()
    public let onLoadMoreMessages = PublishSubject<Void>()
    public let onLogout = PublishSubject<Void>()

    init(_ chatViewController: ChatViewController, _ user: UserData) {
        self.chatViewController = chatViewController
        self.user = user

        chatViewController.set(user: user)
        chatViewController.onLoadMoreMessages.bind(to: onLoadMoreMessages).disposed(by: disposeBag)
        chatViewController.onLogout.bind(to: onLogout).disposed(by: disposeBag)

        chatViewController.onMessageSend.bind { [weak self] text in
            self?.onMessageSend.onNext(text)
            self?.chatViewController.clearMessageInputBar()
        }.disposed(by: disposeBag)
    }

    public func startedHistoryRequest() {
        chatViewController.beginRefreshing()
    }

    public func finishedHistoryRequest() {
        chatViewController.endRefreshing()
    }

    public func addMessage(_ message: ChatMessageData) {
        let messageViewData = ChatViewData(with: message)
        self.addMessageViewData(messageViewData)

        chatViewController.set(viewData: viewData)

        if message.userId == user.userId || chatViewController.isLastSectionVisible {
            chatViewController.reloadDataScrollingToBottom(animated: true)
        } else {
            chatViewController.reloadDataKeepingOffset()
        }
    }

    public func addHistory(_ messages: [ChatMessageData]) {
        let messagesWereEmpty = chatViewController.numberOfMessages == 0

        messages.forEach { message in
            let messageViewData = ChatViewData(with: message)
            self.addMessageViewData(messageViewData)
        }

        chatViewController.set(viewData: viewData)

        if messagesWereEmpty {
            chatViewController.reloadDataScrollingToBottom(animated: false)
        } else {
            chatViewController.reloadDataKeepingOffset()
        }

        if messages.contains(where: {$0.messageId == 0}) {
            chatViewController.disableRefreshControl()
        }
    }

    public func updateViewData(for messageId: Int, with userData: UserData) {
        guard let idx = viewData.firstIndex(where: { $0.messageData.messageId == messageId }) else { return }

        var data = viewData[idx]
        data.userData = userData
        viewData[idx] = data

        chatViewController.set(viewData: viewData)
        chatViewController.reloadDataKeepingOffset()
    }

    var viewData: [ChatViewData] = []
    let user: UserData
    weak var chatViewController: ChatViewController!
    let disposeBag = DisposeBag()
}

extension ChatPresenter {
    func addMessageViewData(_ messageViewData: ChatViewData) {
        if let idx = viewData.firstIndex(where: { $0.messageData.messageId >= messageViewData.messageData.messageId }) {
            if viewData[idx].messageData.messageId != messageViewData.messageData.messageId {
                viewData.insert(messageViewData, at: idx)
            }
        } else {
            viewData.append(messageViewData)
        }
    }
}
