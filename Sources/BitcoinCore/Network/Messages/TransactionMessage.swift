//
//  TransactionMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/4.
//

import Foundation

import SWExtensions

public struct TransactionMessage: IMessage {
    // MARK: Properties

    let transaction: FullTransaction
    let size: Int

    // MARK: Computed Properties

    public var description: String {
        "\(transaction.header.dataHash.sw.reversedHex)"
    }

    // MARK: Lifecycle

    public init(transaction: FullTransaction, size: Int) {
        self.transaction = transaction
        self.size = size
    }
}
