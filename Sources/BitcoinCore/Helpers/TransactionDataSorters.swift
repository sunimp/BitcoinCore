//
//  TransactionDataSorters.swift
//  BitcoinCore
//
//  Created by Sun on 2020/3/16.
//

import Foundation

// MARK: - Bip69Sorter

class Bip69Sorter: ITransactionDataSorter {
    func sort(outputs: [Output]) -> [Output] {
        outputs.sorted(by: Bip69.outputComparator)
    }

    func sort(unspentOutputs: [UnspentOutput]) -> [UnspentOutput] {
        unspentOutputs.sorted(by: Bip69.inputComparator)
    }
}

// MARK: - ShuffleSorter

class ShuffleSorter: ITransactionDataSorter {
    func sort(outputs: [Output]) -> [Output] {
        outputs.shuffled()
    }

    func sort(unspentOutputs: [UnspentOutput]) -> [UnspentOutput] {
        unspentOutputs.shuffled()
    }
}

// MARK: - StraightSorter

class StraightSorter: ITransactionDataSorter {
    func sort(outputs: [Output]) -> [Output] {
        outputs
    }

    func sort(unspentOutputs: [UnspentOutput]) -> [UnspentOutput] {
        unspentOutputs
    }
}
