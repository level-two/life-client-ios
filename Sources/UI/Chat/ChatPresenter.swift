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
    public var inputBarText: String {
        get {
            return chatViewController.messageInputBar.inputTextView.text
        }
        set {
            chatViewController.messageInputBar.inputTextView.text = newValue
        }
    }
    
    init() {
        chatViewController.refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: loadMoreMessages)
            .disposed(by: disposeBag)
    }
    
    fileprivate let chatViewController = ChatViewController()
    fileprivate let disposeBag = DisposeBag()
}

//extension ChatPresenter {
//    private func updateViewWithMessage(_ message: ChatMessageData) {
//        addMessage(message: message)
//        messagesCollectionView.reloadData()
//
//        if message.user.userName == user.userName || isLastSectionVisible() {
//            messagesCollectionView.scrollToBottom(animated: true)
//        } else {
//            // TODO: show arrow button to scroll down or badge
//        }
//    }
//
//    private func updateViewWithHistory(_ chatMessages: [ChatMessageData]) {
//        let messagesWereEmpty = (messages.count == 0)
//        chatMessages?.forEach(addMessage)
//
//        if messagesWereEmpty {
//            messagesCollectionView.reloadData()
//            messagesCollectionView.scrollToBottom(animated: false)
//        } else {
//            refreshControl.endRefreshing()
//            messagesCollectionView.reloadDataAndKeepOffset()
//        }
//
//        if self.messages.count == 0 || messages.first?.id == 0 {
//            messagesCollectionView.refreshControl = nil
//        }
//    }
//
//    private func isLastSectionVisible() -> Bool {
//        guard messages.isEmpty == false else { return false }
//        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
//        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
//    }
//}

