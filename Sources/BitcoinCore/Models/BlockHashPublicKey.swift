//
//  BlockHashPublicKey.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

import GRDB

// MARK: - BlockHashPublicKey

public class BlockHashPublicKey: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case blockHash
        case publicKeyPath
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "blockHashPublicKeys"
    }

    // MARK: Properties

    let blockHash: Data
    var publicKeyPath: String

    // MARK: Lifecycle

    public init(blockHash: Data, publicKeyPath: String) {
        self.blockHash = blockHash
        self.publicKeyPath = publicKeyPath

        super.init()
    }

    required init(row: Row) throws {
        blockHash = row[Columns.blockHash]
        publicKeyPath = row[Columns.publicKeyPath]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.blockHash] = blockHash
        container[Columns.publicKeyPath] = publicKeyPath
    }
}

// MARK: Equatable

extension BlockHashPublicKey: Equatable {
    public static func == (lhs: BlockHashPublicKey, rhs: BlockHashPublicKey) -> Bool {
        lhs.blockHash == rhs.blockHash && lhs.publicKeyPath == rhs.publicKeyPath
    }
}

// MARK: Hashable

extension BlockHashPublicKey: Hashable {
    public var hashValue: Int {
        blockHash.hashValue ^ publicKeyPath.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockHash)
        hasher.combine(publicKeyPath)
    }
}
