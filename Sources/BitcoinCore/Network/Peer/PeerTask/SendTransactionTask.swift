//
//  SendTransactionTask.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/18.
//

import Foundation
import SWExtensions

class SendTransactionTask: PeerTask {
    // MARK: Overridden Properties

    override var state: String {
        "transaction: \(transaction.header.dataHash.sw.reversedHex)"
    }

    // MARK: Properties

    var transaction: FullTransaction

    private let allowedIdleTime: TimeInterval

    // MARK: Lifecycle

    init(
        transaction: FullTransaction,
        allowedIdleTime: TimeInterval = 30,
        dateGenerator: @escaping () -> Date = Date.init
    ) {
        self.transaction = transaction
        self.allowedIdleTime = allowedIdleTime

        super.init(dateGenerator: dateGenerator)
    }

    // MARK: Overridden Functions

    override func start() {
        let message = InventoryMessage(inventoryItems: [
            InventoryItem(type: InventoryItem.ObjectType.transaction.rawValue, hash: transaction.header.dataHash),
        ])

        requester?.send(message: message)

        super.start()
    }

    override func handle(message: IMessage) throws -> Bool {
        var handled = false

        if let getDataMessage = message as? GetDataMessage {
            // We assume that this is the only task waiting for all inventories in this message
            // Otherwise, it means that we also must feed other tasks with this message
            // and we must have a smarter message handling mechanism
            for item in getDataMessage.inventoryItems {
                if handle(getDataInventoryItem: item) {
                    handled = true
                }
            }
        }

        return handled
    }

    override func checkTimeout() {
        if let lastActiveTime {
            if dateGenerator().timeIntervalSince1970 - lastActiveTime > allowedIdleTime {
                delegate?.handle(completedTask: self)
            }
        }
    }

    // MARK: Functions

    func equalTo(_ task: SendTransactionTask?) -> Bool {
        guard let task else {
            return false
        }

        return transaction.header.dataHash == task.transaction.header.dataHash
    }

    private func handle(getDataInventoryItem item: InventoryItem) -> Bool {
        guard item.objectType == .transaction, item.hash == transaction.header.dataHash else {
            return false
        }

        requester?.send(message: TransactionMessage(transaction: transaction, size: 0))
        delegate?.handle(completedTask: self)

        return true
    }
}
