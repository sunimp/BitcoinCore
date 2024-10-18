//
//  TransactionMetadata.swift
//  BitcoinCore
//
//  Created by Sun on 2021/9/3.
//

import Foundation

import GRDB

// MARK: - TransactionType

public enum TransactionType: Int, DatabaseValueConvertible, Codable {
    case incoming = 1
    case outgoing = 2
    case sentToSelf = 3
}

// MARK: - TransactionFilterType

public enum TransactionFilterType {
    case incoming
    case outgoing

    // MARK: Computed Properties

    var types: [TransactionType] {
        switch self {
        case .incoming: [.incoming, .sentToSelf]
        case .outgoing: [.outgoing, .sentToSelf]
        }
    }
}

// MARK: - TransactionMetadata

public class TransactionMetadata: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression, CaseIterable {
        case transactionHash
        case amount
        case type
        case fee
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "transaction_metadata"
    }

    // MARK: Properties

    public var transactionHash: Data
    public var amount: Int
    public var type: TransactionType
    public var fee: Int?

    // MARK: Lifecycle

    public init(transactionHash: Data = Data(), amount: Int = 0, type: TransactionType = .incoming, fee: Int? = nil) {
        self.transactionHash = transactionHash
        self.amount = amount
        self.type = type
        self.fee = fee

        super.init()
    }

    required init(row: Row) throws {
        transactionHash = row[Columns.transactionHash]
        amount = row[Columns.amount]
        type = row[Columns.type]
        fee = row[Columns.fee]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) throws {
        container[Columns.transactionHash] = transactionHash
        container[Columns.amount] = amount
        container[Columns.type] = type
        container[Columns.fee] = fee
    }
}
