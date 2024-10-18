//
//  GetBlocksMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import SWExtensions

struct GetBlocksMessage: IMessage {
    // MARK: Properties

    /// the protocol version
    let version: UInt32
    /// number of block locator hash entries
    let hashCount: VarInt
    /// block locator object; newest back to genesis block (dense to start, but then sparse)
    let blockLocatorHashes: [Data]
    /// hash of the last desired block; set to zero to get as many blocks as possible (500)
    let hashStop: Data

    // MARK: Computed Properties

    var description: String {
        "\(blockLocatorHashes.map(\.sw.reversedHex))"
    }

    // MARK: Lifecycle

    init(protocolVersion: Int32, headerHashes: [Data]) {
        version = UInt32(protocolVersion)
        hashCount = VarInt(headerHashes.count)
        blockLocatorHashes = headerHashes
        hashStop = Data(count: 32)
    }
}
