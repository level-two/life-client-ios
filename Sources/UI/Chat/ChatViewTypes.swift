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
    let id: Int
    let text: String
    
    let userId: UserId
    var userName: String
    var color: Color
}

extension ChatViewMessage: MessageType {
    var sender: SenderType {
        return Sender(senderId: String(userId), displayName: userName)
    }
    
    var messageId: String {
        return String(id)
    }

    var sentDate: Date {
        return Date()
    }

    var kind: MessageKind {
        return .text(text)
    }
}

extension ChatViewMessage {
    static var dummy: ChatViewMessage {
        return .init(id: 0, text: "", userId: 0, userName: "", color: UIColor.black.color)
    }
}
