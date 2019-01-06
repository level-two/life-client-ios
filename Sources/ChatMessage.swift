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
import MessageKit

/*
struct ChatMessage {
    let userName: String
    let message: String
    let messageIntId: Int
    
    init(userName: String, message: String, messageIntId: Int) {
        self.userName = userName
        self.message = message
        self.messageIntId = messageIntId
    }
    
    init?(withDictionary jsonDictionary: Any) {
        guard
            let data = jsonDictionary as? [String: Any],
            let userName = data["userName"] as? String,
            let message = data["message"] as? String,
            let messageIntId = data["messageId"] as? Int
        else {
            print("Failed to create User from provided dictionary:\n \(jsonDictionary)")
            return nil
        }
        
        self.userName = userName
        self.message = message
        self.messageIntId = messageIntId
    }
    
    var toDictionary: Any {
        return [
            "userName": userName,
            "message": message,
            "messageId": messageIntId
        ]
    }
}
 */
