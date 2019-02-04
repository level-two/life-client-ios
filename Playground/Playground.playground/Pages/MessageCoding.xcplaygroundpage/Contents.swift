//: [Previous](@previous)

import Foundation
import UIKit


extension String: Error {}

struct Color: Codable {
    let r, g, b, a: CGFloat
}

extension Color {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        r = try container.decode(CGFloat.self)/255
        g = try container.decode(CGFloat.self)/255
        b = try container.decode(CGFloat.self)/255
        a = try container.decode(CGFloat.self)/255
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(Int(r*255))
        try container.encode(Int(g*255))
        try container.encode(Int(b*255))
        try container.encode(Int(a*255))
    }
}

extension Color {
    var uiColor: UIColor { return UIColor(color: self) }
    var cgColor: CGColor { return uiColor.cgColor }
    var ciColor: CIColor { return CIColor(color: uiColor) }
    var data: Data { return try! JSONEncoder().encode(self) }
}

extension UIColor {
    convenience init(color: Color) {
        self.init(red: color.r, green: color.g, blue: color.b, alpha: color.a)
    }
    var color: Color {
        let color = CIColor(color: self)
        return Color(r: color.red, g: color.green, b: color.blue, a: color.alpha)
    }
}

struct User: Codable {
    var userName: String
    var userId: Int?
    var color: Color
}

struct ChatMessage: Codable {
    let user: User
    let message: String
    let id: Int
}

enum Message: Codable {
    case createUser(user: User)
    case login(userName: String)
    case logout(userName: String)
    
    case createUserResponse(user: User?, error: String?)
    case loginResponse(user: User?, error: String?)
    case logoutResponse(user: User?, error: String?)
    
    case chatMessage(message: ChatMessage)
    case chatMessages(messages: [ChatMessage]?, error: String?)
    case getChatMessages(fromId: Int?, count: Int?)
}

extension Message {
    private enum CodingKeys: String, CodingKey {
        case createUser
        case login
        case logout
        
        case createUserResponse
        case loginResponse
        case logoutResponse
        
        case chatMessage
        case chatMessages
        case getChatMessages
    }
    
    private enum AuxCodingKeys: String, CodingKey {
        case user
        case error
        case messages
        case fromId
        case count
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else { throw "No valid keys in: \(container)" }
        func dec<T: Decodable>() throws -> T { return try container.decode(T.self, forKey: key) }
        func dec<T: Decodable>(_ auxKey: AuxCodingKeys) throws -> T {
            return try container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: key).decode(T.self, forKey: auxKey)
        }
        switch key {
        case .login:              self = try .login(userName: dec())
        case .logout:             self = try .logout(userName: dec())
        case .createUser:         self = try .createUser(user: dec())
            
        case .createUserResponse: self = try .createUserResponse(user: dec(.user), error: dec(.error))
        case .loginResponse:      self = try .loginResponse(user: dec(.user), error: dec(.error))
        case .logoutResponse:     self = try .logoutResponse(user: dec(.user), error: dec(.error))
            
        case .chatMessage:        self = try .chatMessage(message: dec())
        case .chatMessages:       self = try .chatMessages(messages: dec(.messages), error: dec(.error))
        case .getChatMessages:    self = try .getChatMessages(fromId: dec(.fromId), count: dec(.count))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .login(let userName):
            try container.encode(userName, forKey:.login)
        case .logout(let userName):
            try container.encode(userName, forKey:.logout)
        case .createUser(let user):
            try container.encode(user, forKey:.createUser)
        case .createUserResponse(let user, let error):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .createUserResponse)
            try nestedContainter.encode(user, forKey:.user)
            try nestedContainter.encode(error, forKey:.error)
        case .loginResponse(let user, let error):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .loginResponse)
            try nestedContainter.encode(user, forKey:.user)
            try nestedContainter.encode(error, forKey:.error)
        case .logoutResponse(let user, let error):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .logoutResponse)
            try nestedContainter.encode(user, forKey:.user)
            try nestedContainter.encode(error, forKey:.error)
        case .chatMessage(let message):
            try container.encode(message, forKey:.chatMessage)
        case .chatMessages(let messages, let error):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .chatMessages)
            try nestedContainter.encode(messages, forKey:.messages)
            try nestedContainter.encode(error, forKey:.error)
        case .getChatMessages(let fromId, let count):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .getChatMessages)
            try nestedContainter.encode(fromId, forKey:.fromId)
            try nestedContainter.encode(count, forKey:.count)
        }
    }
}

func test(_ message: Message) throws {
    let data = try JSONEncoder().encode(message)
    print(String(data: data, encoding:.utf8)!)
    let decodedMessage = try JSONDecoder().decode(Message.self, from: data)
    print(decodedMessage)
    print()
}

let user = User(userName:"Boris", userId:nil, color:UIColor(red: 0.25, green: 0.1, blue:0.94404, alpha:1.0).color)
let message = ChatMessage(user: user, message: "Chat message", id: 123)

test(.createUser(user: user))
test(.login(userName: "Name"))
test(.logout(userName: "Name"))

test(.createUserResponse(user: user, error: "Error description"))
test(.createUserResponse(user: nil, error: "Error description"))
test(.createUserResponse(user: user, error: nil))
test(.createUserResponse(user: nil, error: nil))

test(.loginResponse(user: user, error: "Error description"))
test(.loginResponse(user: nil, error: "Error description"))
test(.loginResponse(user: user, error: nil))
test(.loginResponse(user: nil, error: nil))

test(.logoutResponse(user: user, error: "Error description"))
test(.logoutResponse(user: nil, error: "Error description"))
test(.logoutResponse(user: user, error: nil))
test(.logoutResponse(user: nil, error: nil))

test(.chatMessage(message: message))

test(.chatMessages(messages: [message, message], error: "Error description"))
test(.chatMessages(messages: nil, error: "Error description"))
test(.chatMessages(messages: [message, message], error: nil))
test(.chatMessages(messages: nil, error: nil))

test(.getChatMessages(fromId: 2, count: 10))
test(.getChatMessages(fromId: nil, count: 10))
test(.getChatMessages(fromId: 2, count: nil))
test(.getChatMessages(fromId: nil, count: nil))
