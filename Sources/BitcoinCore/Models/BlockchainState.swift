//
//  BlockchainState.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/1.
//

import Foundation

import GRDB

class BlockchainState: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case primaryKey
        case initialRestored
    }

    // MARK: Static Properties

    private static let primaryKey = "primaryKey"

    // MARK: Overridden Properties

    override class var databaseTableName: String {
        "blockchainStates"
    }

    // MARK: Properties

    var initialRestored: Bool?

    private let primaryKey: String = BlockchainState.primaryKey

    // MARK: Lifecycle

    override init() {
        super.init()
    }

    required init(row: Row) throws {
        initialRestored = row[Columns.initialRestored]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override func encode(to container: inout PersistenceContainer) throws {
        container[Columns.primaryKey] = primaryKey
        container[Columns.initialRestored] = initialRestored
    }
}
