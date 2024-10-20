//
//  MempoolTransactions.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/3.
//

import Combine
import Foundation

// MARK: - MempoolTransactions

class MempoolTransactions {
    // MARK: Properties

    private var cancellables = Set<AnyCancellable>()
    private let transactionSyncer: ITransactionSyncer
    private let transactionSender: ITransactionSender?
    private var requestedTransactions = [String: [Data]]()
    private let peersQueue: DispatchQueue

    // MARK: Lifecycle

    init(
        transactionSyncer: ITransactionSyncer,
        transactionSender: ITransactionSender?,
        peersQueue: DispatchQueue = DispatchQueue(
            label: "com.sunimp.bitcoin-core.mempool-transactions",
            qos: .userInitiated
        )
    ) {
        self.transactionSyncer = transactionSyncer
        self.transactionSender = transactionSender
        self.peersQueue = peersQueue
    }

    // MARK: Functions

    func subscribeTo(publisher: AnyPublisher<PeerGroupEvent, Never>) {
        publisher
            .sink { [weak self] event in
                switch event {
                case let .onPeerDisconnect(peer, error): self?.onPeerDisconnect(peer: peer, error: error)
                default: ()
                }
            }
            .store(in: &cancellables)
    }

    private func addToRequestTransactions(peerHost: String, transactionHashes: [Data]) {
        peersQueue.async {
            if (!self.requestedTransactions.contains { key, _ in key == peerHost }) {
                self.requestedTransactions[peerHost] = [Data]()
            }
            self.requestedTransactions[peerHost]?.append(contentsOf: transactionHashes)
        }
    }

    private func removeFromRequestedTransactions(peerHost: String, transactionHashes: [Data]) {
        peersQueue.async {
            for transactionHash in transactionHashes {
                if let index = self.requestedTransactions[peerHost]?.firstIndex(of: transactionHash) {
                    self.requestedTransactions[peerHost]?.remove(at: index)
                }
            }
        }
    }

    private func isTransactionRequested(hash: Data) -> Bool {
        peersQueue.sync {
            for hashes in self.requestedTransactions {
                if hashes.value.contains(hash) {
                    return true
                }
            }
            return false
        }
    }
}

// MARK: IPeerTaskHandler

extension MempoolTransactions: IPeerTaskHandler {
    func handleCompletedTask(peer: IPeer, task: PeerTask) -> Bool {
        switch task {
        case let task as RequestTransactionsTask:
            transactionSyncer.handleRelayed(transactions: task.transactions)
            removeFromRequestedTransactions(
                peerHost: peer.host,
                transactionHashes: task.transactions.map(\.header.dataHash)
            )
            transactionSender?.transactionsRelayed(transactions: task.transactions)
            return true

        default: return false
        }
    }
}

// MARK: IInventoryItemsHandler

extension MempoolTransactions: IInventoryItemsHandler {
    func handleInventoryItems(peer: IPeer, inventoryItems: [InventoryItem]) {
        var transactionHashes = [Data]()

        for item in inventoryItems {
            if
                case .transaction = item.objectType, !isTransactionRequested(hash: item.hash),
                transactionSyncer.shouldRequestTransaction(hash: item.hash) {
                transactionHashes.append(item.hash)
            }
        }

        if !transactionHashes.isEmpty {
            peer.add(task: RequestTransactionsTask(hashes: transactionHashes))

            addToRequestTransactions(peerHost: peer.host, transactionHashes: transactionHashes)
        }
    }
}

extension MempoolTransactions {
    private func onPeerDisconnect(peer: IPeer, error _: Error?) {
        peersQueue.async {
            self.requestedTransactions[peer.host] = nil
        }
    }
}
