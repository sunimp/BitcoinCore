//
//  MerkleBlockMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import SWExtensions

// MARK: - MerkleBlockMessage

struct MerkleBlockMessage: IMessage {
    // MARK: Properties

    let blockHeader: BlockHeader

    /// Number of transactions in the block (including unmatched ones)
    let totalTransactions: UInt32
    /// hashes in depth-first order (including standard varint size prefix)
    let numberOfHashes: VarInt
    let hashes: [Data]
    /// flag bits, packed per 8 in a byte, least significant bit first (including standard varint size prefix)
    let numberOfFlags: VarInt
    let flags: [UInt8]

    // MARK: Computed Properties

    var description: String {
        "\(blockHeader.headerHash.sw.reversedHex)"
    }
}

// MARK: Equatable

extension MerkleBlockMessage: Equatable {
    static func == (lhs: MerkleBlockMessage, rhs: MerkleBlockMessage) -> Bool {
        lhs.blockHeader.headerHash == rhs.blockHeader.headerHash &&
            lhs.totalTransactions == rhs.totalTransactions &&
            lhs.numberOfHashes.underlyingValue == rhs.numberOfHashes.underlyingValue &&
            lhs.hashes == rhs.hashes
    }
}
