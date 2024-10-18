//
//  TransactionDataSorterFactory.swift
//  BitcoinCore
//
//  Created by Sun on 2020/3/16.
//

import Foundation

class TransactionDataSorterFactory: ITransactionDataSorterFactory {
    func sorter(for type: TransactionDataSortType) -> ITransactionDataSorter {
        switch type {
        case .none: StraightSorter()
        case .shuffle: ShuffleSorter()
        case .bip69: Bip69Sorter()
        }
    }
}
