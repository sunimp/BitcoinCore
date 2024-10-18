//
//  RequestTransactionsTask.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/18.
//

import Foundation

class RequestTransactionsTask: PeerTask {
    // MARK: Overridden Properties

    override var state: String {
        "hashesCount: \(hashes.count); receivedTransactionsCount: \(transactions.count)"
    }

    // MARK: Properties

    var transactions = [FullTransaction]()

    private var hashes: [Data]

    // MARK: Lifecycle

    init(hashes: [Data]) {
        self.hashes = hashes
    }

    // MARK: Overridden Functions

    override func start() {
        let items = hashes.map { hash in
            InventoryItem(type: InventoryItem.ObjectType.transaction.rawValue, hash: hash)
        }

        requester?.send(message: GetDataMessage(inventoryItems: items))

        super.start()
    }

    override func handle(message: IMessage) throws -> Bool {
        if let transactionMessage = message as? TransactionMessage {
            return handle(transaction: transactionMessage.transaction)
        }
        return false
    }

    // MARK: Functions

    func equalTo(_ task: RequestTransactionsTask?) -> Bool {
        guard let task else {
            return false
        }

        return hashes == task.hashes
    }

    private func handle(transaction: FullTransaction) -> Bool {
        guard let index = hashes.firstIndex(where: { $0 == transaction.header.dataHash }) else {
            return false
        }

        hashes.remove(at: index)
        transactions.append(transaction)

        if hashes.isEmpty {
            delegate?.handle(completedTask: self)
        }

        return true
    }
}
