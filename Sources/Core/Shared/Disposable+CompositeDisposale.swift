//
//  Disposable+CompositeDisposale.swift
//  LifeClient
//
//  Created by Yauheni Lychkouski on 5/11/19.
//  Copyright © 2019 Yauheni Lychkouski. All rights reserved.
//

import Foundation
import RxSwift

extension Disposable {
    /// Adds `self` to `compositeDisposable`
    ///
    /// - parameter compositeDisposable: `CompositeDisposable` to add `self` to.
    @discardableResult
    public func disposed(by compositeDisposable: CompositeDisposable) -> CompositeDisposable.DisposeKey? {
        return compositeDisposable.insert(self)
    }
}
