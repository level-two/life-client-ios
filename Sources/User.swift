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

struct User {
    var userName: String
    var userId: Int
    var color: [Double]
    
    var toDictionary: Any {
        return [
            "userName": userName,
            "userId": userId,
            "color": color
        ]
    }
    
    init?(withDictionary jsonDictionary: Any) {
        guard
            let data = jsonDictionary as? [String: Any],
            let userName = data["userName"] as? String,
            let userId = data["userId"] as? Int,
            let color = data["color"] as? [Double],
            color.count == 4
        else {
            print("Failed to create User from provided dictionary:\n \(jsonDictionary)")
            return nil
        }
        
        self.userName = userName
        self.userId = userId
        self.color = color
    }
}
