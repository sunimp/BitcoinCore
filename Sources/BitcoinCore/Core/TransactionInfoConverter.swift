//
//  TransactionInfoConverter.swift
//  BitcoinCore
//
//  Created by Sun on 2019/5/3.
//

import Foundation

open class TransactionInfoConverter: ITransactionInfoConverter {
    // MARK: Properties

    public var baseTransactionInfoConverter: IBaseTransactionInfoConverter!

    // MARK: Lifecycle

    public init() { }

    // MARK: Functions

    public func transactionInfo(fromTransaction transactionForInfo: FullTransactionForInfo) -> TransactionInfo {
        baseTransactionInfoConverter.transactionInfo(fromTransaction: transactionForInfo)
    }
}
