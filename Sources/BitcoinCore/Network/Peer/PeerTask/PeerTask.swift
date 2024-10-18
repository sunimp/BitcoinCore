//
//  PeerTask.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/18.
//

import Foundation

// MARK: - PeerTask

open class PeerTask {
    // MARK: Nested Types

    class TimeoutError: Error { }

    // MARK: Properties

    public let dateGenerator: () -> Date
    public var lastActiveTime: Double?

    public weak var requester: IPeerTaskRequester?
    public weak var delegate: IPeerTaskDelegate?

    // MARK: Computed Properties

    open var state: String { "" }

    // MARK: Lifecycle

    public init(dateGenerator: @escaping () -> Date = Date.init) {
        self.dateGenerator = dateGenerator
    }

    // MARK: Functions

    open func start() {
        resetTimer()
    }

    open func handle(message _: IMessage) throws -> Bool {
        false
    }

    open func checkTimeout() { }

    open func resetTimer() {
        lastActiveTime = dateGenerator().timeIntervalSince1970
    }
}

// MARK: Equatable

extension PeerTask: Equatable {
    public static func == (lhs: PeerTask, rhs: PeerTask) -> Bool {
        switch lhs {
        case let t as GetBlockHashesTask: t.equalTo(rhs as? GetBlockHashesTask)
        case let t as GetMerkleBlocksTask: t.equalTo(rhs as? GetMerkleBlocksTask)
        case let t as SendTransactionTask: t.equalTo(rhs as? SendTransactionTask)
        case let t as RequestTransactionsTask: t.equalTo(rhs as? RequestTransactionsTask)
        default: true
        }
    }
}
