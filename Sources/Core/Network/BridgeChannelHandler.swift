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
import RxSwift
import RxCocoa

class BridgeChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = String

    public let onMessage = PublishSubject<String>()
    public let disposeBag = DisposeBag()

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let unwrappedData = self.unwrapInboundIn(data)
        // Think about json validation before using it
        // we could have also sanitized the user input by using a regular expression in our route path to make sure that the incoming value was a single letter
        print("Got: \(unwrappedData)")
        onMessage.onNext(unwrappedData)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Bridge caught error: ", error)
        context.close(promise: nil)
    }
}
