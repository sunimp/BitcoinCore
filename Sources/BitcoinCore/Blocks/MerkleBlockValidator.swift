//
//  MerkleBlockValidator.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

class MerkleBlockValidator: IMerkleBlockValidator {
    // MARK: Properties

    private let maxBlockSize: UInt32
    private var merkleBranch: IMerkleBranch?

    // MARK: Lifecycle

    init(maxBlockSize: UInt32, merkleBranch: IMerkleBranch? = nil) {
        self.maxBlockSize = maxBlockSize
        self.merkleBranch = merkleBranch
    }

    // MARK: Functions

    func set(merkleBranch: IMerkleBranch) {
        self.merkleBranch = merkleBranch
    }

    func merkleBlock(from message: MerkleBlockMessage) throws -> MerkleBlock {
        // An empty set will not work
        guard message.totalTransactions > 0 else {
            throw BitcoinCoreErrors.MerkleBlockValidation.noTransactions
        }

        // check for excessively high numbers of transactions
        guard message.totalTransactions <= maxBlockSize / 60
        else { // 60 is the lower bound for the size of a serialized CTransaction
            throw BitcoinCoreErrors.MerkleBlockValidation.tooManyTransactions
        }

        // there can never be more hashes provided than one for every txid
        guard message.hashes.count <= message.totalTransactions else {
            throw BitcoinCoreErrors.MerkleBlockValidation.moreHashesThanTransactions
        }
        // there must be at least one bit per node in the partial tree, and at least one node per hash
        guard message.flags.count * 8 >= message.hashes.count else {
            throw BitcoinCoreErrors.MerkleBlockValidation.matchedBitsFewerThanHashes
        }

        guard let merkleBranch else {
            throw BitcoinCoreErrors.MerkleBlockValidation.noMerkleBranch
        }
        let merkleRootData = try merkleBranch.calculateMerkleRoot(
            txCount: Int(message.totalTransactions),
            hashes: message.hashes,
            flags: message.flags
        )

        guard merkleRootData.merkleRoot == message.blockHeader.merkleRoot else {
            throw BitcoinCoreErrors.MerkleBlockValidation.wrongMerkleRoot
        }

        return MerkleBlock(
            header: message.blockHeader,
            transactionHashes: merkleRootData.matchedHashes,
            transactions: [FullTransaction]()
        )
    }
}
