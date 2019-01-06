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
import NIO
import NIOFoundationCompat


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

struct ChatMessage: Codable {
    let user: User
    let message: String
    let id: Int
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
    
    func decodeWrapped<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        let wrapped = try self.decode(DecodableWrapper<T>.self, from: data)
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
    
    func encodeWrapped<T>(_ value: T) throws -> Data where T : Encodable {
        return try self.encode(EncodableWrapper(value))
    }
}

class NetworkEvents {
    let createUserResponse   = Event<CreateUserResponse>()
    let loginResponse        = Event<LoginResponse>()
    let logoutResponse       = Event<LogoutResponse>()
    let chatMessage          = Event<ChatMessage>()
    let chatMessagesResponse = Event<ChatMessagesResponse>()
    
    func produceEvent(withJsonData jsonData: Data) {
        if let msg = try? JSONDecoder().decodeWrapped(CreateUserResponse.self, from: jsonData) {
            createUserResponse.raise(with: msg)
        }
        else if let msg = try? JSONDecoder().decodeWrapped(LoginResponse.self, from: jsonData) {
            loginResponse.raise(with: msg)
        }
        else if let msg = try? JSONDecoder().decodeWrapped(LogoutResponse.self, from: jsonData) {
            logoutResponse.raise(with: msg)
        }
        else if let msg = try? JSONDecoder().decodeWrapped(ChatMessage.self, from: jsonData) {
            chatMessage.raise(with: msg)
        }
        else if let msg = try? JSONDecoder().decodeWrapped(ChatMessagesResponse.self, from: jsonData) {
            chatMessagesResponse.raise(with: msg)
        }
        else {
            print("Failed to decode object from JSON")
        }
    }
}


final class ChannelInboundBridge: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias MessageHandler = (Data) -> Void

    private let messageHandler: MessageHandler
    
    init(messageHandler: @escaping MessageHandler) {
        self.messageHandler = messageHandler
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuf = self.unwrapInboundIn(data)
        guard let data = byteBuf.getData(at:byteBuf.readerIndex, length:byteBuf.readableBytes) else { return }
        self.messageHandler(data)
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("JsonDesChannelInboundHandler error: ", error)
        ctx.close(promise: nil)
    }
}


class NetworkManager {
    // MARK: - Types
    enum ConnectionState {
        case none
        case connected
    }
    
    enum NetworkManagerError: Error {
        case error(String)
    }
    
    typealias ConnectionStateHandler = (ConnectionState)->()
    
    // MARK: - Variables
    let networkEvents: NetworkEvents
    let host = "localhost"
    let port = 1337
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var bootstrap: ClientBootstrap {
        let inboundBridge = ChannelInboundBridge { [weak self] jsonData in
            self?.networkEvents.produceEvent(withJsonData: jsonData)
        }
        
        return ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in channel.pipeline.add(handler: inboundBridge)
        }
    }
    var channel: Channel? = nil
    var connectionStateHandler: ConnectionStateHandler?
    var isConnected = false {
        didSet {
            connectionStateHandler?(isConnected ? .connected : .none)
        }
    }
    
    // MARK: - Methods
    init(networkEvents: NetworkEvents) {
        self.networkEvents = networkEvents
        connectToServer()
    }
    
    @discardableResult
    func send<T>(message: T) -> Future<Void> where T: Encodable {
        let promise = Promise<Void>()
        
        guard let jsonData = try? JSONEncoder().encodeWrapped(message) else {
            promise.reject(with: NetworkManagerError.error("Failed to serialize to JSON"))
            return promise
        }
        
        print("Sending: \(String(data: jsonData, encoding: .utf8)!)")
        
        guard let ch = self.channel else {
            promise.reject(with: NetworkManagerError.error("No Connection"))
            return promise
        }
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            promise.reject(with: NetworkManagerError.error("Conversion from jsonData to String failed"))
            return promise
        }
        
        var buffer = ch.allocator.buffer(capacity: jsonString.count)
        buffer.write(string: jsonString)
        
        let writePromise = ch.writeAndFlush(buffer)
        writePromise.whenSuccess {
            print("Message sent")
            promise.resolve(with: ())
        }
        writePromise.whenFailure { error in
            print("Failed to send message: \(error)")
            promise.reject(with: error)
        }
        
        return promise
    }
    
    private func connectToServer() {
        print("Connecting to \(host):\(port)...")
        let channelFuture = self.bootstrap.connect(host: self.host, port: self.port)
        
        channelFuture.whenFailure { [weak self] error in
            print("Connection failed: \(error)")
            self?.isConnected = false
        }
        
        channelFuture.whenSuccess { [weak self] channel in
            print("Connected")
            self?.channel = channel
            self?.isConnected = true
            
            self?.channel?.closeFuture.whenSuccess { [weak self] in
                print("Connection closed")
                self?.isConnected = false
                self?.channel = nil
                sleep(1)
                self?.connectToServer()
            }
            
            self?.channel?.closeFuture.whenFailure { [weak self] error in
                print("Disconnected with error: \(error)")
                self?.isConnected = false
                self?.channel = nil
                sleep(1)
                self?.connectToServer()
            }
        }
    }
    
    private func closeConnection() {
        _ = self.channel?.close()
    }
}
