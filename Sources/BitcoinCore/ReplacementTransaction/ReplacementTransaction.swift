//
//  ReplacementTransaction.swift
//  BitcoinCore
//
//  Created by Sun on 2024/2/13.
//

import Foundation

public struct ReplacementTransaction {
    let mutableTransaction: MutableTransaction
    public let info: TransactionInfo
    public let replacedTransactionHashes: [String]
}
