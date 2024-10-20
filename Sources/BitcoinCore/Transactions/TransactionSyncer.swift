//
//  TransactionSyncer.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/25.
//

import Foundation

// MARK: - TransactionSyncer

public class TransactionSyncer {
    // MARK: Properties

    private let storage: IStorage
    private let processor: IPendingTransactionProcessor
    private let invalidator: TransactionInvalidator
    private let publicKeyManager: IPublicKeyManager

    // MARK: Lifecycle

    init(
        storage: IStorage,
        processor: IPendingTransactionProcessor,
        invalidator: TransactionInvalidator,
        publicKeyManager: IPublicKeyManager
    ) {
        self.storage = storage
        self.processor = processor
        self.invalidator = invalidator
        self.publicKeyManager = publicKeyManager
    }
}

// MARK: ITransactionSyncer

extension TransactionSyncer: ITransactionSyncer {
    public func newTransactions() -> [FullTransaction] {
        storage.newTransactions()
    }

    public func handleRelayed(transactions: [FullTransaction]) {
        guard !transactions.isEmpty else {
            return
        }

        var needToUpdateBloomFilter = false

        do {
            try processor.processReceived(transactions: transactions, skipCheckBloomFilter: false)
        } catch _ as BloomFilterManager.BloomFilterExpired {
            needToUpdateBloomFilter = true
        } catch { }

        if needToUpdateBloomFilter {
            try? publicKeyManager.fillGap()
        }
    }

    public func handleInvalid(fullTransaction: FullTransaction) {
        invalidator.invalidate(transaction: fullTransaction.header)
    }

    public func shouldRequestTransaction(hash: Data) -> Bool {
        !storage.relayedTransactionExists(byHash: hash)
    }
}
