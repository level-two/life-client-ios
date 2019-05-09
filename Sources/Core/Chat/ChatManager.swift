// -----------------------------------------------------------------------------
//    Copyright (C) 2019 Yauheni Lychkouski.
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
import RxCocoa
import PromiseKit

class ChatManager {
    public enum ChatManagerError: Error {
        case operationTimeout
    }
    
    public let onMessage = PublishSubject<ChatMessageData>()
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        
        assembleInteractions()
    }
    
    public func send(messageText: String) -> Promise<Void> {
        let message = ChatManagerMessage.sendChatMessage(message: messageText)
        return networkManager.send(message)
    }
    
    public func requestHIstory(fromId: Int, count: Int) -> Promise<[ChatMessageData]> {
        return firstly {
            sendHistoryRequest(fromId: fromId, count: count)
        }.then {
            waitHistoryResponse()
        }
    }
    
    let networkManager: NetworkManager
    let disposeBag = DisposeBag()
}

extension ChatManager {
    func assembleInteractions() {
        networkManager.onMessage.bind { [weak self] message in
            guard let self = self else { return }
            guard case NetworkManagerMessage.chatMessage(let chatMessageData) = message else { return }
            self.onMessage.onNext(chatMessageData)
        }.disposed(by: disposeBag)
    }
}

extension ChatManager {
    func sendHistoryRequest(fromId: Int, count: Int) -> Promise<Void> {
        let message = ChatManagerMessage.chatHistoryRequest(fromId: fromId, count: count)
        return networkManager.send(message)
    }
    
    func waitHistoryResponse() -> Promise<[ChatMessageData]> {
        return .init() { promise in
            let compositeDisposable = CompositeDisposable()
            
            self.networkManager.onMessage
                .bind { message in
                    guard case ChatManagerMessage.chatHistoryResponse(let messages) = message else { return }
                    promise.resolve(with: messages)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
            
            self.networkManager.onMessage
                .bind { message in
                    guard case ChatManagerMessage.chatHistoryError(let error) = message else { return }
                    promise.reject(error)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
            
            let timeout = ApplicationSettings.operationTimeout
            
            Observable<Int>
                .timer(.init(timeout), period: nil, scheduler: MainScheduler.instance)
                .bind {
                    promise.reject(ChatManagerError.operationTimeout)
                    compositeDisposable.dispose()
                }.disposed(by: compositeDisposable)
        }
    }
}
