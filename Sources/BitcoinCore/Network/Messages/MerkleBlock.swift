//
//  MerkleBlock.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/6.
//

import Foundation

public class MerkleBlock {
    // MARK: Properties

    let header: BlockHeader
    let transactionHashes: [Data]
    var height: Int?
    var transactions: [FullTransaction]

    lazy var headerHash: Data = self.header.headerHash

    // MARK: Computed Properties

    var complete: Bool {
        transactionHashes.count == transactions.count
    }

    // MARK: Lifecycle

    init(header: BlockHeader, transactionHashes: [Data], transactions: [FullTransaction]) {
        self.header = header
        self.transactionHashes = transactionHashes
        self.transactions = transactions
    }
}
