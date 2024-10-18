//
//  LockTimeSetter.swift
//  BitcoinCore
//
//  Created by Sun on 2019/10/4.
//

import Foundation

// MARK: - LockTimeSetter

class LockTimeSetter {
    // MARK: Properties

    private let storage: IStorage

    // MARK: Lifecycle

    init(storage: IStorage) {
        self.storage = storage
    }
}

// MARK: ILockTimeSetter

extension LockTimeSetter: ILockTimeSetter {
    func setLockTime(to mutableTransaction: MutableTransaction) {
        mutableTransaction.transaction.lockTime = storage.lastBlock?.height ?? 0
    }
}
