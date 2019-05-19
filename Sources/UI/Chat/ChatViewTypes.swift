//
//  ChatViewTypes.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 5/14/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation
import MessageKit

struct ChatViewData {
    var messageData: ChatMessageData
    var userData: UserData?

    init(with messageData: ChatMessageData) {
        self.messageData = messageData
    }
}

extension ChatViewData: MessageType {
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

extension ChatViewData {
    var avatarBackgroundColor: UIColor {
        return userData?.color.uiColor ?? .clear
    }
}

extension ChatViewData {
    static var dummy: ChatViewData {
        return .init(with: ChatMessageData(messageId: 0, userId: 0, text: ""))
    }
}
