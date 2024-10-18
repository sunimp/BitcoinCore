//
//  PendingOutpointsProvider.swift
//  BitcoinCore
//
//  Created by Sun on 2020/1/8.
//

import Foundation

// MARK: - PendingOutpointsProvider

class PendingOutpointsProvider {
    // MARK: Properties

    weak var bloomFilterManager: IBloomFilterManager?

    private let storage: IStorage

    // MARK: Lifecycle

    init(storage: IStorage) {
        self.storage = storage
    }
}

// MARK: IBloomFilterProvider

extension PendingOutpointsProvider: IBloomFilterProvider {
    func filterElements() -> [Data] {
        let hashes = storage.incomingPendingTransactionHashes()

        return storage.inputs(byHashes: hashes).map {
            $0.previousOutputTxHash + byteArrayLittleEndian(int: $0.previousOutputIndex)
        }
    }
}
