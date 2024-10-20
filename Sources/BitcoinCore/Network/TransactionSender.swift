//
//  TransactionSender.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/3.
//

import Combine
import Foundation
import QuartzCore

import SWToolKit

// MARK: - TransactionSender

class TransactionSender {
    // MARK: Static Properties

    static let minConnectedPeersCount = 2

    // MARK: Properties

    private var cancellables = Set<AnyCancellable>()

    private let transactionSyncer: ITransactionSyncer
    private let initialBlockDownload: IInitialDownload
    private let peerManager: IPeerManager
    private let storage: IStorage
    private let timer: ITransactionSendTimer
    private let logger: Logger?
    private let queue: DispatchQueue

    private let sendType: BitcoinCore.SendType
    private let maxRetriesCount: Int
    private let retriesPeriod: Double // seconds

    // MARK: Lifecycle

    init(
        transactionSyncer: ITransactionSyncer,
        initialBlockDownload: IInitialDownload,
        peerManager: IPeerManager,
        storage: IStorage,
        timer: ITransactionSendTimer,
        logger: Logger? = nil,
        queue: DispatchQueue = DispatchQueue(label: "com.sunimp.bitcoin-core.transaction-sender", qos: .background),
        sendType: BitcoinCore.SendType,
        maxRetriesCount: Int = 3,
        retriesPeriod: Double = 60
    ) {
        self.transactionSyncer = transactionSyncer
        self.initialBlockDownload = initialBlockDownload
        self.peerManager = peerManager
        self.storage = storage
        self.timer = timer
        self.logger = logger
        self.queue = queue
        self.sendType = sendType
        self.maxRetriesCount = maxRetriesCount
        self.retriesPeriod = retriesPeriod
    }

    // MARK: Functions

    private func peersToSendTo() -> [IPeer] {
        let syncedPeers = initialBlockDownload.syncedPeers
        guard let freeSyncedPeer = syncedPeers.sorted(by: { !$0.ready && $1.ready }).first else {
            return []
        }

        guard peerManager.totalPeersCount >= TransactionSender.minConnectedPeersCount else {
            return []
        }

        let sortedPeers = peerManager.readyPeers
            .filter {
                freeSyncedPeer !== $0
            }
            .sorted { (a: IPeer, b: IPeer) in
                !syncedPeers.contains(where: { a === $0 }) && syncedPeers.contains(where: { b === $0 })
            }

        if sortedPeers.count == 1 {
            return sortedPeers
        }

        return Array(sortedPeers.prefix(sortedPeers.count / 2))
    }

    private func transactionsToSend(from transactions: [FullTransaction]) -> [FullTransaction] {
        transactions.filter { transaction in
            if let sentTransaction = storage.sentTransaction(byHash: transaction.header.dataHash) {
                sentTransaction.lastSendTime < CACurrentMediaTime() - self.retriesPeriod
            } else {
                true
            }
        }
    }

    private func transactionSendSuccess(sentTransaction transaction: FullTransaction) {
        guard
            let sentTransaction = storage.sentTransaction(byHash: transaction.header.dataHash),
            !sentTransaction.sendSuccess
        else {
            return
        }

        sentTransaction.retriesCount = sentTransaction.retriesCount + 1
        sentTransaction.sendSuccess = true

        if sentTransaction.retriesCount >= maxRetriesCount {
            transactionSyncer.handleInvalid(fullTransaction: transaction)
            storage.delete(sentTransaction: sentTransaction)
        } else {
            storage.update(sentTransaction: sentTransaction)
        }
    }

    private func transactionSendStart(transaction: FullTransaction) {
        if let sentTransaction = storage.sentTransaction(byHash: transaction.header.dataHash) {
            sentTransaction.lastSendTime = CACurrentMediaTime()
            sentTransaction.sendSuccess = false
            storage.update(sentTransaction: sentTransaction)
        } else {
            storage.add(sentTransaction: SentTransaction(dataHash: transaction.header.dataHash))
        }
    }

    private func apiSend(transactions: [FullTransaction], blockchairApi: BlockchairApi) {
        Task(priority: .userInitiated) {
            for transaction in transactions {
                do {
                    try await blockchairApi
                        .broadcastTransaction(hex: TransactionSerializer.serialize(transaction: transaction))
                    transactionSyncer.handleRelayed(transactions: [transaction])
                } catch {
                    transactionSyncer.handleInvalid(fullTransaction: transaction)
                }
            }
        }
    }

    private func p2pSend(transactions: [FullTransaction]) {
        let peers = peersToSendTo()
        guard !peers.isEmpty else {
            return
        }

        timer.startIfNotRunning()

        for transaction in transactions {
            transactionSendStart(transaction: transaction)

            for peer in peers {
                peer.add(task: SendTransactionTask(transaction: transaction))
            }
        }
    }

    private func send(transactions: [FullTransaction]) {
        switch sendType {
        case .p2p:
            p2pSend(transactions: transactions)
        case let .api(blockchairApi):
            apiSend(transactions: transactions, blockchairApi: blockchairApi)
        }
    }

    private func sendPendingTransactions() {
        var transactions = transactionSyncer.newTransactions()

        guard !transactions.isEmpty else {
            timer.stop()
            return
        }

        transactions = transactionsToSend(from: transactions)

        guard !transactions.isEmpty else {
            return
        }

        send(transactions: transactions)
    }
}

// MARK: ITransactionSender

extension TransactionSender: ITransactionSender {
    func verifyCanSend() throws {
        if peersToSendTo().isEmpty {
            throw BitcoinCoreErrors.TransactionSendError.peersNotSynced
        }
    }

    func send(pendingTransaction: FullTransaction) {
        queue.async {
            self.send(transactions: [pendingTransaction])
        }
    }

    func transactionsRelayed(transactions: [FullTransaction]) {
        queue.async {
            for transaction in transactions {
                if let sentTransaction = self.storage.sentTransaction(byHash: transaction.header.dataHash) {
                    self.storage.delete(sentTransaction: sentTransaction)
                }
            }
        }
    }

    func subscribeTo(publisher: AnyPublisher<InitialDownloadEvent, Never>) {
        publisher
            .sink { [weak self] event in
                switch event {
                case .onAllPeersSynced:
                    self?.queue.async {
                        self?.sendPendingTransactions()
                    }

                default: ()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: ITransactionSendTimerDelegate

extension TransactionSender: ITransactionSendTimerDelegate {
    func timePassed() {
        queue.async {
            self.sendPendingTransactions()
        }
    }
}

// MARK: IPeerTaskHandler

extension TransactionSender: IPeerTaskHandler {
    func handleCompletedTask(peer _: IPeer, task: PeerTask) -> Bool {
        switch task {
        case let task as SendTransactionTask:
            queue.async {
                self.transactionSendSuccess(sentTransaction: task.transaction)
            }
            return true

        default: return false
        }
    }
}
