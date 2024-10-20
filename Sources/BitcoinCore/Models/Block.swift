//
//  Block.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import GRDB

public class Block: Record {
    // MARK: Nested Types

    public enum Columns: String, ColumnExpression, CaseIterable {
        case version
        case previousBlockHash
        case merkleRoot
        case timestamp
        case bits
        case nonce
        case headerHash
        case height
        case stale
        case hasTransactions
        case partial
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "blocks"
    }

    // MARK: Properties

    public var version: Int
    public var previousBlockHash: Data
    public var merkleRoot: Data
    public var timestamp: Int
    public var bits: Int
    public var nonce: Int

    public var headerHash: Data
    public var height: Int

    var stale = false
    var hasTransactions = false
    var partial = false

    // MARK: Lifecycle

    public init(withHeader header: BlockHeader, height: Int) {
        version = header.version
        previousBlockHash = header.previousBlockHeaderHash
        merkleRoot = header.merkleRoot
        timestamp = header.timestamp
        bits = header.bits
        nonce = header.nonce
        headerHash = header.headerHash
        self.height = height

        super.init()
    }

    public convenience init(withHeader header: BlockHeader, previousBlock: Block) {
        self.init(withHeader: header, height: previousBlock.height + 1)
    }

    required init(row: Row) throws {
        version = row[Columns.version]
        previousBlockHash = row[Columns.previousBlockHash]
        merkleRoot = row[Columns.merkleRoot]
        timestamp = row[Columns.timestamp]
        bits = row[Columns.bits]
        nonce = row[Columns.nonce]
        headerHash = row[Columns.headerHash]
        height = row[Columns.height]
        stale = row[Columns.stale]
        hasTransactions = row[Columns.hasTransactions]
        partial = row[Columns.partial]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) throws {
        container[Columns.version] = version
        container[Columns.previousBlockHash] = previousBlockHash
        container[Columns.merkleRoot] = merkleRoot
        container[Columns.timestamp] = timestamp
        container[Columns.bits] = bits
        container[Columns.nonce] = nonce
        container[Columns.headerHash] = headerHash
        container[Columns.height] = height
        container[Columns.stale] = stale
        container[Columns.hasTransactions] = hasTransactions
        container[Columns.partial] = partial
    }
}
