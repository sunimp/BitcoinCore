//
//  IrregularOutputFinder.swift
//  BitcoinCore
//
//  Created by Sun on 2018/10/17.
//

import Foundation

// MARK: - IrregularOutputFinder

class IrregularOutputFinder {
    // MARK: Properties

    weak var bloomFilterManager: IBloomFilterManager?

    private let irregularScriptTypes: [ScriptType]
    private let storage: IStorage

    // MARK: Lifecycle

    init(storage: IStorage, additionalScripts: [ScriptType]) {
        self.storage = storage
        irregularScriptTypes = ([.p2wpkh, .p2pk, .p2wpkhSh, .p2tr] + additionalScripts).unique
    }

    // MARK: Functions

    private func needToSetToBloomFilter(output: OutputWithPublicKey, bestBlockHeight: Int) -> Bool {
        // Need to set if output is unspent
        guard let _ = output.spendingInput else {
            return true
        }

        if let spendingBlockHeight = output.spendingBlockHeight {
            // If output is spent, we still need to set to bloom filter if it hasn't at least 100 confirmations
            return bestBlockHeight - spendingBlockHeight < 100
        }

        // if output is spent by a mempool transaction, that is, spending input's transaction has not a block
        return true
    }
}

// MARK: IIrregularOutputFinder

extension IrregularOutputFinder: IIrregularOutputFinder {
    func hasIrregularOutput(outputs: [Output]) -> Bool {
        for output in outputs {
            if output.publicKeyPath != nil, irregularScriptTypes.contains(output.scriptType) {
                return true
            }
        }

        return false
    }
}

// MARK: IBloomFilterProvider

extension IrregularOutputFinder: IBloomFilterProvider {
    func filterElements() -> [Data] {
        var elements = [Data]()

        var outputs = storage.outputsWithPublicKeys().filter { irregularScriptTypes.contains($0.output.scriptType) }

        if let bestBlockHeight = storage.lastBlock?.height {
            outputs = outputs.filter {
                self.needToSetToBloomFilter(output: $0, bestBlockHeight: bestBlockHeight)
            }
        }

        for outputWithPublicKey in outputs {
            let outpoint = outputWithPublicKey.output
                .transactionHash + byteArrayLittleEndian(int: outputWithPublicKey.output.index)
            elements.append(outpoint)
        }

        return elements
    }
}
