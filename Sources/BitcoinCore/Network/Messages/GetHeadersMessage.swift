//
//  GetHeadersMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import SWExtensions

struct GetHeadersMessage: IMessage {
    // MARK: Properties

    /// the protocol version
    let version: UInt32
    /// number of block locator hash entries
    let hashCount: VarInt
    /// block locator object; newest back to genesis block (dense to start, but then sparse)
    let blockLocatorHashes: [Data]
    /// hash of the last desired header; set to zero to get as many headers as possible (2000)
    let hashStop: Data

    let description = ""

    // MARK: Lifecycle

    init(protocolVersion: Int32, headerHashes: [Data]) {
        version = UInt32(protocolVersion)
        hashCount = VarInt(headerHashes.count)
        blockLocatorHashes = headerHashes
        hashStop = Data(count: 32)
    }
}
