//
//  SentTransaction.swift
//  BitcoinCore
//
//  Created by Sun on 2018/11/12.
//

import Foundation

import GRDB
import QuartzCore

public class SentTransaction: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case dataHash
        case lastSendTime
        case retriesCount
        case sendSuccess
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "sentTransactions"
    }

    // MARK: Properties

    let dataHash: Data
    var lastSendTime: Double
    var retriesCount: Int
    var sendSuccess: Bool

    // MARK: Lifecycle

    init(dataHash: Data, lastSendTime: Double, retriesCount: Int, sendSuccess: Bool) {
        self.dataHash = dataHash
        self.lastSendTime = lastSendTime
        self.retriesCount = retriesCount
        self.sendSuccess = sendSuccess

        super.init()
    }

    convenience init(dataHash: Data) {
        self.init(dataHash: dataHash, lastSendTime: CACurrentMediaTime(), retriesCount: 0, sendSuccess: false)
    }

    required init(row: Row) throws {
        dataHash = row[Columns.dataHash]
        lastSendTime = row[Columns.lastSendTime]
        retriesCount = row[Columns.retriesCount]
        sendSuccess = row[Columns.sendSuccess]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) throws {
        container[Columns.dataHash] = dataHash
        container[Columns.lastSendTime] = lastSendTime
        container[Columns.retriesCount] = retriesCount
        container[Columns.sendSuccess] = sendSuccess
    }
}
