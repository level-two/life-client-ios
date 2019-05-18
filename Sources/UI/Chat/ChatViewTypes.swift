//
//  ChatViewTypes.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 5/14/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation
import MessageKit

struct MessageViewData {
    var messageData: ChatMessageData
    var userData: UserData?
    
    init(with messageData: ChatMessageData) {
        self.messageData = messageData
    }
}

extension MessageViewData: MessageType {
    var sender: SenderType {
        return Sender(senderId: String(messageData.userId),
                      displayName: userData?.userName ?? "")
    }

    var messageId: String {
        return String(messageData.messageId)
    }

    var sentDate: Date {
        return Date()
    }

    var kind: MessageKind {
        return .text(messageData.text)
    }
}

extension MessageViewData {
    static var dummy: MessageViewData {
        return .init(messageData: ChatMessageData(messageId: 0, userId: 0, text: ""),
                     userData: UserData(userId: 0, userName: "", color: UIColor.clear.color))
    }
}
