//
//  BlockHash.swift
//  BitcoinCore
//
//  Created by Sun on 2018/10/17.
//

import Foundation

import GRDB
import SWExtensions

// MARK: - BlockHash

public class BlockHash: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case headerHash
        case height
        case sequence
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "blockHashes"
    }

    // MARK: Properties

    let headerHash: Data
    let height: Int
    let sequence: Int

    // MARK: Lifecycle

    public init(headerHash: Data, height: Int, order: Int) {
        self.headerHash = headerHash
        self.height = height
        sequence = order

        super.init()
    }

    init?(headerHashReversedHex: String?, height: Int?, sequence: Int) {
        guard let hex = headerHashReversedHex, let height, let headerHash = hex.sw.hexData else {
            return nil
        }

        self.headerHash = Data(headerHash.reversed())
        self.height = height
        self.sequence = sequence

        super.init()
    }

    required init(row: Row) throws {
        headerHash = row[Columns.headerHash]
        height = row[Columns.height]
        sequence = row[Columns.sequence]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) throws {
        container[Columns.headerHash] = headerHash
        container[Columns.height] = height
        container[Columns.sequence] = sequence
    }
}

// MARK: Equatable

extension BlockHash: Equatable {
    public static func == (lhs: BlockHash, rhs: BlockHash) -> Bool {
        lhs.headerHash == rhs.headerHash
    }
}

// MARK: Hashable

extension BlockHash: Hashable {
    public var hashValue: Int {
        headerHash.hashValue ^ height.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(headerHash)
        hasher.combine(height)
    }
}
