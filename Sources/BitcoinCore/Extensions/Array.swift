//
//  Array.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import GRDB

extension [FullTransaction] {
    func inTopologicalOrder() -> [FullTransaction] {
        var ordered = [FullTransaction]()

        var visited = [Bool](repeating: false, count: count)

        for i in 0 ..< count {
            visit(transactionWithIndex: i, picked: &ordered, visited: &visited)
        }

        return ordered
    }

    private func visit(
        transactionWithIndex transactionIndex: Int,
        picked: inout [FullTransaction],
        visited: inout [Bool]
    ) {
        guard !picked.contains(where: { self[transactionIndex].header.dataHash == $0.header.dataHash }) else {
            return
        }

        guard !visited[transactionIndex] else {
            return
        }

        visited[transactionIndex] = true

        for candidateTransactionIndex in 0 ..< count {
            for input in self[transactionIndex].inputs {
                if
                    input.previousOutputTxHash == self[candidateTransactionIndex].header.dataHash,
                    self[candidateTransactionIndex].outputs.count > input.previousOutputIndex {
                    visit(transactionWithIndex: candidateTransactionIndex, picked: &picked, visited: &visited)
                }
            }
        }

        visited[transactionIndex] = false
        picked.append(self[transactionIndex])
    }
}

extension Array where Element: Hashable {
    var unique: [Element] {
        Array(Set(self))
    }
}

// MARK: - SQLExpressible + SQLExpressible
#if compiler(>=6)
extension [Data]: @retroactive SQLExpressible { }
#else
extension [Data]: SQLExpressible {}
#endif

extension [Data] {
    public var sqlExpression: SQLExpression {
        databaseValue.sqlExpression
    }
}

// MARK: - DatabaseValueConvertible + DatabaseValueConvertible, StatementBinding
#if compiler(>=6)
extension [Data]: @retroactive DatabaseValueConvertible, StatementBinding { }
#else
extension [Data]: DatabaseValueConvertible, StatementBinding {}
#endif

extension [Data] {
    public var databaseValue: DatabaseValue {
        DataListSerializer.serialize(dataList: self).databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> [Element]? {
        if case let DatabaseValue.Storage.blob(value) = dbValue.storage {
            return DataListSerializer.deserialize(data: value)
        }

        return nil
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
