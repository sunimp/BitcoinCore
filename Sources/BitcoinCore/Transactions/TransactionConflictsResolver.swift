//
//  TransactionConflictsResolver.swift
//  BitcoinCore
//
//  Created by Sun on 2020/9/24.
//

import Foundation

// MARK: - TransactionConflictsResolver

class TransactionConflictsResolver {
    // MARK: Properties

    private let storage: IStorage

    // MARK: Lifecycle

    init(storage: IStorage) {
        self.storage = storage
    }

    // MARK: Functions

    private func conflictingTransactions(for transaction: FullTransaction) -> [Transaction] {
        let storageTransactionHashes = transaction.inputs
            .map { input in
                storage.inputsUsing(
                    previousOutputTxHash: input.previousOutputTxHash,
                    previousOutputIndex: input.previousOutputIndex
                )
                .filter { $0.transactionHash != transaction.header.dataHash }
                .map(\.transactionHash)
            }
            .flatMap { $0 }

        guard !storageTransactionHashes.isEmpty else {
            return []
        }

        return storage.transactions(hashes: storageTransactionHashes)
    }

    private func existingHasHigherSequence(
        mempoolTransaction: FullTransaction,
        existingTransaction: FullTransaction
    )
        -> Bool {
        for existingInput in existingTransaction.inputs {
            if
                let mempoolInput = mempoolTransaction.inputs.first(where: {
                    $0.previousOutputTxHash == existingInput.previousOutputTxHash &&
                        $0.previousOutputIndex == existingInput.previousOutputIndex
                }) {
                if existingInput.sequence > mempoolInput.sequence {
                    return true
                }
            }
        }

        return false
    }
}

// MARK: ITransactionConflictsResolver

extension TransactionConflictsResolver: ITransactionConflictsResolver {
    /// Only pending transactions may be conflicting with a transaction in block. No need to check that
    func transactionsConflicting(withInblockTransaction transaction: FullTransaction) -> [Transaction] {
        conflictingTransactions(for: transaction)
    }

    func transactionsConflicting(withPendingTransaction transaction: FullTransaction) -> [Transaction] {
        let conflictingTransactions = conflictingTransactions(for: transaction)

        guard !conflictingTransactions.isEmpty else {
            return []
        }

        // If any of conflicting transactions is already in a block, then current transaction is invalid and non of them
        // is conflicting with it.
        guard conflictingTransactions.allSatisfy({ $0.blockHash == nil }) else {
            return []
        }

        let conflictingFullTransactions = storage.fullTransactions(from: conflictingTransactions)

        return conflictingFullTransactions
            // If an existing transaction has a conflicting input with higher sequence,
            // then mempool transaction most probably has been received before
            // and the existing transaction is a replacement transaction that is not relayed in mempool yet.
            // Other cases are theoretically possible, but highly unlikely
            .filter { !existingHasHigherSequence(mempoolTransaction: transaction, existingTransaction: $0) }
            .map(\.header)
    }

    /// Checks if the transactions has a conflicting input with higher sequence
    func isTransactionReplaced(transaction: FullTransaction) -> Bool {
        let conflictingTransactions = conflictingTransactions(for: transaction)

        guard !conflictingTransactions.isEmpty, conflictingTransactions.allSatisfy({ $0.blockHash == nil }) else {
            return false
        }

        let conflictingFullTransactions = storage.fullTransactions(from: conflictingTransactions)

        return conflictingFullTransactions
            .contains { existingHasHigherSequence(mempoolTransaction: transaction, existingTransaction: $0) }
    }

    func incomingPendingTransactionsConflicting(with transaction: FullTransaction) -> [Transaction] {
        let pendingTxHashes = storage.incomingPendingTransactionHashes()
        if pendingTxHashes.isEmpty {
            return []
        }

        let conflictingTransactionHashes = storage
            .inputs(byHashes: pendingTxHashes)
            .filter { input in
                transaction.inputs
                    .contains {
                        $0.previousOutputIndex == input.previousOutputIndex && $0.previousOutputTxHash == input
                            .previousOutputTxHash
                    }
            }
            .map(\.transactionHash)
        if
            conflictingTransactionHashes
                .isEmpty { // handle if transaction has conflicting inputs, otherwise it's false-positive tx
            return []
        }

        return Array(Set(conflictingTransactionHashes)) // make unique elements
            .compactMap { storage.transaction(byHash: $0) } // get transactions for each input
            .filter { $0.blockHash == nil } // exclude all transactions in blocks
    }
}
