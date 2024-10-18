//
//  FilterLoadMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

struct FilterLoadMessage: IMessage {
    // MARK: Properties

    let bloomFilter: BloomFilter

    // MARK: Computed Properties

    var description: String {
        "\(bloomFilter.elementsCount) item(s)"
    }

    // MARK: Lifecycle

    init(bloomFilter: BloomFilter) {
        self.bloomFilter = bloomFilter
    }
}
