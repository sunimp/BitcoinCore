//
//  GetBlockHashesTask.swift
//  BitcoinCore
//
//  Created by Sun on 2018/10/17.
//

import Foundation

class GetBlockHashesTask: PeerTask {
    // MARK: Overridden Properties

    override var state: String {
        "expectedHashesMinCount: \(expectedHashesMinCount); allowedIdleTime: \(allowedIdleTime)"
    }

    // MARK: Properties

    var blockHashes = [Data]()

    private let maxAllowedIdleTime = 10.0
    private let minAllowedIdleTime = 1.0
    private let maxExpectedBlockHashesCount: Int32 = 500
    private let minExpectedBlockHashesCount: Int32 = 6

    private let blockLocatorHashes: [Data]
    private let expectedHashesMinCount: Int32
    private let allowedIdleTime: Double

    // MARK: Lifecycle

    init(hashes: [Data], expectedHashesMinCount: Int32, dateGenerator: @escaping () -> Date = Date.init) {
        blockLocatorHashes = hashes

        var resolvedExpectedHashesMinCount = expectedHashesMinCount
        if resolvedExpectedHashesMinCount < minExpectedBlockHashesCount {
            resolvedExpectedHashesMinCount = minExpectedBlockHashesCount
        }
        if resolvedExpectedHashesMinCount > maxExpectedBlockHashesCount {
            resolvedExpectedHashesMinCount = maxExpectedBlockHashesCount
        }

        var resolvedAllowedIdleTime = Double(resolvedExpectedHashesMinCount) * maxAllowedIdleTime /
            Double(maxExpectedBlockHashesCount)
        if resolvedAllowedIdleTime < minAllowedIdleTime {
            resolvedAllowedIdleTime = minAllowedIdleTime
        }

        self.expectedHashesMinCount = resolvedExpectedHashesMinCount
        allowedIdleTime = resolvedAllowedIdleTime

        super.init(dateGenerator: dateGenerator)
    }

    // MARK: Overridden Functions

    override func start() {
        if let requester {
            requester.send(message: GetBlocksMessage(
                protocolVersion: requester.protocolVersion,
                headerHashes: blockLocatorHashes
            ))
        }

        super.start()
    }

    override func handle(message: IMessage) throws -> Bool {
        if let inventoryMessage = message as? InventoryMessage {
            return handle(items: inventoryMessage.inventoryItems)
        }
        return false
    }

    override func checkTimeout() {
        if let lastActiveTime {
            if dateGenerator().timeIntervalSince1970 - lastActiveTime > allowedIdleTime {
                delegate?.handle(completedTask: self)
            }
        }
    }

    // MARK: Functions

    func equalTo(_ task: GetBlockHashesTask?) -> Bool {
        guard let task else {
            return false
        }

        return blockLocatorHashes == task.blockLocatorHashes && expectedHashesMinCount == task.expectedHashesMinCount
    }

    private func handle(items: [InventoryItem]) -> Bool {
        let newHashes = items
            .filter { item in item.objectType == .blockMessage }
            .map { item in item.hash }

        guard !newHashes.isEmpty else {
            return false
        }

        resetTimer()

        for hash in newHashes {
            if blockLocatorHashes.contains(hash) {
                // If peer sends us a hash which we have in blockLocatorHashes, it means it's just a stale block hash.
                // Because, otherwise it doesn't conform with P2P protocol
                return true
            }
        }

        if blockHashes.count < newHashes.count {
            blockHashes = newHashes
        }

        if newHashes.count >= expectedHashesMinCount {
            delegate?.handle(completedTask: self)
        }

        return true
    }
}
