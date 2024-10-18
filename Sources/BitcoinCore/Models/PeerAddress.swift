//
//  PeerAddress.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/13.
//

import Foundation

import GRDB

public class PeerAddress: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case ip
        case score
        case connectionTime
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "peerAddresses"
    }

    // MARK: Properties

    let ip: String
    var score: Int
    var connectionTime: Double?

    // MARK: Lifecycle

    public init(ip: String, score: Int) {
        self.ip = ip
        self.score = score

        super.init()
    }

    required init(row: Row) throws {
        ip = row[Columns.ip]
        score = row[Columns.score]
        connectionTime = row[Columns.connectionTime]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) throws {
        container[Columns.ip] = ip
        container[Columns.score] = score
        container[Columns.connectionTime] = connectionTime
    }
}
