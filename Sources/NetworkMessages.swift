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

struct CreateUser: Encodable {
    let user: User
}

struct CreateUserResponse: Decodable {
    let user: User?
    let error: String?
}

struct Login: Encodable {
    let userName: String
}

struct LoginResponse: Decodable {
    let user: User?
    let error: String?
}

struct Logout: Encodable {
    let userName: String
}

struct LogoutResponse: Decodable {
    let user: User?
    let error: String?
}

struct SendChatMessage: Encodable {
    let message: String
}

struct ChatMessage: Decodable {
    let user: User
    let message: String
    let id: Int
}

struct ChatError: Decodable {
    let error: String
}

struct GetRecentChatMessages: Encodable {
}

struct GetChatMessages: Encodable {
    let fromId: Int
    let count: Int
}

struct ChatMessagesResponse: Decodable {
    let chatHistory: [ChatMessage]?
    let error: String?
}


class NetworkMessages {
    enum NetworkMessagesError: Error {
        case error(String)
    }
    
    let networkManager: NetworkManager
    let createUserResponse   = Event1<CreateUserResponse>()
    let loginResponse        = Event1<LoginResponse>()
    let logoutResponse       = Event1<LogoutResponse>()
    let chatMessage          = Event1<ChatMessage>()
    let chatError            = Event1<ChatError>()
    let chatMessagesResponse = Event1<ChatMessagesResponse>()
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.networkManager.messageHandler = { [weak self] jsonString in
            guard let self = self else { return }
            
            print("Received message: \(jsonString)")
            
            if let msg = try? JSONDecoder().decodeWrapped(CreateUserResponse.self, from: jsonString) {
                self.createUserResponse.raise(with: msg)
            }
            else if let msg = try? JSONDecoder().decodeWrapped(LoginResponse.self, from: jsonString) {
                self.loginResponse.raise(with: msg)
            }
            else if let msg = try? JSONDecoder().decodeWrapped(LogoutResponse.self, from: jsonString) {
                self.logoutResponse.raise(with: msg)
            }
            else if let msg = try? JSONDecoder().decodeWrapped(ChatMessage.self, from: jsonString) {
                self.chatMessage.raise(with: msg)
            }
            else if let msg = try? JSONDecoder().decodeWrapped(ChatError.self, from: jsonString) {
                self.chatError.raise(with: msg)
            }
            else if let msg = try? JSONDecoder().decodeWrapped(ChatMessagesResponse.self, from: jsonString) {
                self.chatMessagesResponse.raise(with: msg)
            }
            else {
                print("Failed to decode object from JSON")
            }
        }
    }
    
    @discardableResult
    func send<T>(message: T) -> Future<Void> where T: Encodable {
        return Promise(value: message)
            .transformed { try JSONEncoder().encodeWrapped($0) }
            .chained { [unowned self] in self.networkManager.send(string: $0) }
    }
}

extension JSONDecoder {
    struct DecodableWrapper<T>: Decodable where T: Decodable {
        let wrapper: T
        
        struct CodingKeyType: CodingKey {
            var stringValue: String = ""
            var intValue: Int? = nil
            init?(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { self.intValue = intValue }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeyType.self)
            let typeName = String(describing: T.self)
            wrapper = try container.decode(T.self, forKey: CodingKeyType(stringValue: typeName)!)
        }
    }
    
    func decodeWrapped<T>(_ type: T.Type, from string: String) throws -> T where T : Decodable {
        let jsonData = string.data(using: .utf8).require()
        let wrapped = try self.decode(DecodableWrapper<T>.self, from: jsonData)
        return wrapped.wrapper
    }
}

extension JSONEncoder {
    struct EncodableWrapper<T>: Encodable where T: Encodable {
        let wrapped: T
        
        init(_ value: T) { self.wrapped = value }
        
        struct CodingKeyType: CodingKey {
            var stringValue: String = ""
            var intValue: Int? = nil
            init?(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { self.intValue = intValue }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeyType.self)
            let typeName = String(describing: T.self)
            try container.encode(wrapped, forKey: CodingKeyType(stringValue: typeName)!)
        }
    }
    
    func encodeWrapped<T>(_ value: T) throws -> String where T : Encodable {
        let jsonData = try self.encode(EncodableWrapper(value))
        return String(data: jsonData, encoding: .utf8).require()
    }
}
