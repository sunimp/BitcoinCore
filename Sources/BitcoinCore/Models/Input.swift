//
//  Input.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/22.
//

import Foundation

import GRDB

// MARK: - Input

public class Input: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression, CaseIterable {
        case previousOutputTxHash
        case previousOutputIndex
        case signatureScript
        case sequence
        case transactionHash
        case keyHash
        case address
        case witnessData
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "inputs"
    }

    // MARK: Properties

    public var previousOutputTxHash: Data
    public var signatureScript: Data

    var previousOutputIndex: Int
    var sequence: Int
    var transactionHash = Data()
    var lockingScriptPayload: Data? = nil
    var address: String? = nil
    var witnessData = [Data]()

    // MARK: Lifecycle

    init(withPreviousOutputTxHash previousOutputTxHash: Data, previousOutputIndex: Int, script: Data, sequence: Int) {
        self.previousOutputTxHash = previousOutputTxHash
        self.previousOutputIndex = previousOutputIndex
        signatureScript = script
        self.sequence = sequence

        super.init()
    }

    required init(row: Row) throws {
        previousOutputTxHash = row[Columns.previousOutputTxHash]
        previousOutputIndex = row[Columns.previousOutputIndex]
        signatureScript = row[Columns.signatureScript]
        sequence = row[Columns.sequence]
        transactionHash = row[Columns.transactionHash]
        lockingScriptPayload = row[Columns.keyHash]
        address = row[Columns.address]
        witnessData = row[Columns.witnessData]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) throws {
        container[Columns.previousOutputTxHash] = previousOutputTxHash
        container[Columns.previousOutputIndex] = previousOutputIndex
        container[Columns.signatureScript] = signatureScript
        container[Columns.sequence] = sequence
        container[Columns.transactionHash] = transactionHash
        container[Columns.keyHash] = lockingScriptPayload
        container[Columns.address] = address
        container[Columns.witnessData] = witnessData
    }
}

extension Input {
    var rbfEnabled: Bool {
        sequence < 0xFFFFFFFE
    }
}

// MARK: - SerializationError

enum SerializationError: Error {
    case noPreviousOutput
    case noPreviousTransaction
    case noPreviousOutputScript
}
