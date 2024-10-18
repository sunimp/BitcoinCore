//
//  WatchedTransactionManager.swift
//  BitcoinCore
//
//  Created by Sun on 2019/7/13.
//

import Foundation

// MARK: - WatchedTransactionManager

class WatchedTransactionManager {
    // MARK: Nested Types

    struct P2ShOutputFilter {
        let hash: Data
        let delegate: IWatchedTransactionDelegate
    }

    struct OutpointFilter {
        let transactionHash: Data
        let outputIndex: Int
        let delegate: IWatchedTransactionDelegate
    }

    // MARK: Properties

    weak var bloomFilterManager: IBloomFilterManager?

    private var p2ShOutputFilters = [P2ShOutputFilter]()
    private var outpointFilters = [OutpointFilter]()
    private let queue: DispatchQueue

    // MARK: Lifecycle

    init(queue: DispatchQueue = DispatchQueue(
        label: "com.sunimp.bitcoin-core.watched-transactions-manager",
        qos: .background
    )) {
        self.queue = queue
    }

    // MARK: Functions

    private func scan(transaction: FullTransaction) {
        for filter in p2ShOutputFilters {
            for output in transaction.outputs {
                if output.scriptType == .p2sh, output.lockingScriptPayload == filter.hash {
                    filter.delegate.transactionReceived(transaction: transaction, outputIndex: output.index)
                    return
                }
            }
        }

        for filter in outpointFilters {
            for (index, input) in transaction.inputs.enumerated() {
                if
                    input.previousOutputTxHash == filter.transactionHash,
                    input.previousOutputIndex == filter.outputIndex {
                    filter.delegate.transactionReceived(transaction: transaction, inputIndex: index)
                    return
                }
            }
        }
    }
}

// MARK: IWatchedTransactionManager

extension WatchedTransactionManager: IWatchedTransactionManager {
    func add(transactionFilter: BitcoinCore.TransactionFilter, delegatedTo delegate: IWatchedTransactionDelegate) {
        switch transactionFilter {
        case let .p2shOutput(scriptHash):
            p2ShOutputFilters.append(P2ShOutputFilter(hash: scriptHash, delegate: delegate))
        case let .outpoint(transactionHash, outputIndex):
            outpointFilters.append(OutpointFilter(
                transactionHash: transactionHash,
                outputIndex: outputIndex,
                delegate: delegate
            ))
        }
        bloomFilterManager?.regenerateBloomFilter()
    }
}

// MARK: ITransactionListener

extension WatchedTransactionManager: ITransactionListener {
    func onReceive(transaction: FullTransaction) {
        queue.async {
            self.scan(transaction: transaction)
        }
    }
}

// MARK: IBloomFilterProvider

extension WatchedTransactionManager: IBloomFilterProvider {
    func filterElements() -> [Data] {
        var elements = [Data]()

        for filter in p2ShOutputFilters {
            elements.append(filter.hash)
        }

        for filter in outpointFilters {
            elements.append(filter.transactionHash + byteArrayLittleEndian(int: filter.outputIndex))
        }

        return elements
    }
}
