//
//  TransactionInvalidator.swift
//  BitcoinCore
//
//  Created by Sun on 2020/9/24.
//

import Foundation

// MARK: - TransactionInvalidator

class TransactionInvalidator {
    // MARK: Properties

    weak var listener: IBlockchainDataListener?

    private let storage: IStorage
    private let transactionInfoConverter: ITransactionInfoConverter

    // MARK: Lifecycle

    init(
        storage: IStorage,
        transactionInfoConverter: ITransactionInfoConverter,
        listener: IBlockchainDataListener? = nil
    ) {
        self.storage = storage
        self.transactionInfoConverter = transactionInfoConverter
        self.listener = listener
    }
}

// MARK: ITransactionInvalidator

extension TransactionInvalidator: ITransactionInvalidator {
    public func invalidate(transaction: Transaction) {
        let invalidTransactionsFullInfo = storage.descendantTransactionsFullInfo(of: transaction.dataHash)

        guard !invalidTransactionsFullInfo.isEmpty else {
            return
        }

        for invalidTransactionsFullInfo in invalidTransactionsFullInfo {
            invalidTransactionsFullInfo.transactionWithBlock.transaction.status = .invalid
        }

        let invalidTransactions: [InvalidTransaction] = invalidTransactionsFullInfo.map { transactionFullInfo in
            let transactionInfo = transactionInfoConverter.transactionInfo(fromTransaction: transactionFullInfo)
            var transactionInfoJson = Data()
            if let jsonData = try? JSONEncoder().encode(transactionInfo) {
                transactionInfoJson = jsonData
            }

            let transaction = transactionFullInfo.transactionWithBlock.transaction
            return InvalidTransaction(
                uid: transaction.uid, dataHash: transaction.dataHash, version: transaction.version,
                lockTime: transaction.lockTime,
                timestamp: transaction.timestamp,
                order: transaction.order, blockHash: transaction.blockHash, isMine: transaction.isMine,
                isOutgoing: transaction.isOutgoing,
                status: transaction.status, segWit: transaction.segWit,
                conflictingTxHash: transaction.conflictingTxHash,
                transactionInfoJson: transactionInfoJson, rawTransaction: transactionFullInfo.rawTransaction
            )
        }

        try? storage.moveTransactionsTo(invalidTransactions: invalidTransactions)
        listener?.onUpdate(updated: invalidTransactions, inserted: [], inBlock: nil)
    }
}
