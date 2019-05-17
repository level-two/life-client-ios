//
//  ChatViewTypes.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 5/14/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation
import MessageKit

struct ChatViewMessage {
    var messageData: ChatMessageData
    var userData: UserData
}

extension ChatViewMessage: MessageType {
    var sender: SenderType {
        return Sender(senderId: String(userData.userId), displayName: userData.userName)
    }

    var messageId: String {
        return String(messageData.id)
    }

    var sentDate: Date {
        return Date()
    }

    var kind: MessageKind {
        return .text(messageData.text)
    }
}

extension ChatViewMessage {
    static var dummy: ChatViewMessage {
        return .init(messageData: ChatMessageData(id: 0, userId: 0, text: ""),
                     userData: UserData(userId: 0, userName: "", color: UIColor.black.color))
    }
}
