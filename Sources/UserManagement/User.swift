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

struct User: Codable {
    var userName: String
    var userId: Int?
    var color: UIColor
    
    enum CodingKeys: String, CodingKey {
        case userName
        case userId
        case color
    }
    
    init(userName: String, userId: Int?, color: UIColor) {
        self.userName = userName
        self.userId = userId
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let values = try  decoder.container(keyedBy: CodingKeys.self)
        userName   = try  values.decode(String.self, forKey: .userName)
        userId     = try? values.decode(Int.self, forKey: .userId)
        
        let colorBytes = try values.decode([Int].self, forKey: .color)
        guard
            colorBytes.count == 4,
            colorBytes.filter({ $0 < 0 && $0 > 255 }).count == 0
        else {
            throw "Failed decode color from JSON"
        }
        
        let cgComponents = colorBytes.map { CGFloat($0)/255.0 }
        self.color = UIColor(red: cgComponents[0], green: cgComponents[1], blue: cgComponents[2], alpha: cgComponents[3])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userName, forKey: .userName)
        try container.encode(userId,   forKey: .userId)
        
        var (r, g, b, a) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) == false {
            throw "Failed to get color components during JSON encoding"
        }
        let colorBytes = [r, g, b, a].map { Int($0*255.0) }
        try container.encode(colorBytes,    forKey: .color)
    }
}
