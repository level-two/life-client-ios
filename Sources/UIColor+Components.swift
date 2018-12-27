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

extension UIColor {
    convenience init?(withRgbComponents components: [Double]) {
        guard components.count == 4 else { return nil }
        let cgComponents = components.map { CGFloat($0) }
        self.init(displayP3Red: cgComponents[0], green: cgComponents[1], blue: cgComponents[2], alpha: cgComponents[3])
    }
    
    func rgbComponents() -> [Double]? {
        var (red, green, blue, alpha) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        {
            return [red, green, blue, alpha].map { Double($0) }
        }
        else {
            return nil
        }
    }
}
