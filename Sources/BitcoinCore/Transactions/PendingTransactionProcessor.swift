//
//  PendingTransactionProcessor.swift
//  BitcoinCore
//
//  Created by Sun on 2020/9/24.
//

import Foundation

// MARK: - PendingTransactionProcessor

class PendingTransactionProcessor {
    // MARK: Properties

    weak var listener: IBlockchainDataListener?
    weak var transactionListener: ITransactionListener?

    private let storage: IStorage
    private let extractor: ITransactionExtractor
    private let publicKeyManager: IPublicKeyManager
    private let irregularOutputFinder: IIrregularOutputFinder
    private let conflictsResolver: ITransactionConflictsResolver
    private let ignoreIncoming: Bool

    private let queue: DispatchQueue

    private var notMineTransactions = Set<Data>()

    // MARK: Lifecycle

    init(
        storage: IStorage,
        extractor: ITransactionExtractor,
        publicKeyManager: IPublicKeyManager,
        irregularOutputFinder: IIrregularOutputFinder,
        conflictsResolver: ITransactionConflictsResolver,
        ignoreIncoming: Bool,
        listener: IBlockchainDataListener? = nil,
        queue: DispatchQueue
    ) {
        self.storage = storage
        self.extractor = extractor
        self.publicKeyManager = publicKeyManager
        self.irregularOutputFinder = irregularOutputFinder
        self.conflictsResolver = conflictsResolver
        self.ignoreIncoming = ignoreIncoming
        self.listener = listener
        self.queue = queue
    }

    // MARK: Functions

    private func relay(transaction: Transaction, order: Int) {
        transaction.status = .relayed
        transaction.order = order
    }

    private func resolveConflicts(transaction: FullTransaction, updated: inout [Transaction]) throws {
        let conflictingTransactions = conflictsResolver.transactionsConflicting(withPendingTransaction: transaction)

        for conflictingTransaction in conflictingTransactions {
            for descendantTransaction in storage.descendantTransactions(of: conflictingTransaction.dataHash) {
                descendantTransaction.conflictingTxHash = transaction.header.dataHash
                try storage.update(transaction: descendantTransaction)
                updated.append(descendantTransaction)
            }
        }
    }
}

// MARK: IPendingTransactionProcessor

extension PendingTransactionProcessor: IPendingTransactionProcessor {
    func processReceived(transactions: [FullTransaction], skipCheckBloomFilter: Bool) throws {
        var needToUpdateBloomFilter = false

        var updated = [Transaction]()
        var inserted = [Transaction]()

        try queue.sync {
            for (index, transaction) in transactions.inTopologicalOrder().enumerated() {
                if notMineTransactions.contains(transaction.header.dataHash) {
                    // already processed this transaction with same state
                    continue
                }

                let invalidTransaction = storage.invalidTransaction(byHash: transaction.header.dataHash)
                if invalidTransaction != nil {
                    // if some peer send us transaction after it's invalidated, we must ignore it
                    continue
                }

                if let existingTransaction = storage.transaction(byHash: transaction.header.dataHash) {
                    try resolveConflicts(transaction: transaction, updated: &updated)

                    if existingTransaction.status == .relayed {
                        // if comes again from memPool we don't need to update it
                        continue
                    }

                    relay(transaction: existingTransaction, order: index)

                    try storage.update(transaction: existingTransaction)
                    updated.append(existingTransaction)

                    continue
                }

                relay(transaction: transaction.header, order: index)
                extractor.extract(transaction: transaction)
                transactionListener?.onReceive(transaction: transaction)

                guard transaction.header.isMine else {
                    notMineTransactions.insert(transaction.header.dataHash)

                    for tx in conflictsResolver.incomingPendingTransactionsConflicting(with: transaction) {
                        // Former incoming transaction is conflicting with current transaction
                        tx.conflictingTxHash = transaction.header.dataHash
                        try storage.update(transaction: tx)
                        updated.append(tx)
                    }

                    continue
                }

                try resolveConflicts(transaction: transaction, updated: &updated)
                if ignoreIncoming, transaction.metaData.type == .incoming {
                    continue
                }

                try storage.add(transaction: transaction)
                inserted.append(transaction.header)

                let needToCheckDoubleSpend = !transaction.header.isOutgoing
                if !skipCheckBloomFilter {
                    needToUpdateBloomFilter = needToUpdateBloomFilter ||
                        needToCheckDoubleSpend ||
                        publicKeyManager.gapShifts() ||
                        irregularOutputFinder.hasIrregularOutput(outputs: transaction.outputs)
                }
            }
        }

        if !updated.isEmpty || !inserted.isEmpty {
            listener?.onUpdate(updated: updated, inserted: inserted, inBlock: nil)
        }

        if needToUpdateBloomFilter {
            throw BloomFilterManager.BloomFilterExpired()
        }
    }

    func processCreated(transaction: FullTransaction) throws {
        guard storage.transaction(byHash: transaction.header.dataHash) == nil else {
            throw TransactionCreator.CreationError.transactionAlreadyExists
        }

        extractor.extract(transaction: transaction)
        try storage.add(transaction: transaction)
        listener?.onUpdate(updated: [], inserted: [transaction.header], inBlock: nil)

        if irregularOutputFinder.hasIrregularOutput(outputs: transaction.outputs) {
            throw BloomFilterManager.BloomFilterExpired()
        }
    }
}
