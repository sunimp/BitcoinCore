//
//  ApiModels.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

import ObjectMapper

// MARK: - ApiTransactionItem

public struct ApiTransactionItem {
    // MARK: Properties

    public let blockHash: String
    public let blockHeight: Int
    public var apiAddressItems: [ApiAddressItem]

    // MARK: Lifecycle

    public init(blockHash: String, blockHeight: Int, apiAddressItems: [ApiAddressItem]) {
        self.blockHash = blockHash
        self.blockHeight = blockHeight
        self.apiAddressItems = apiAddressItems
    }
}

// MARK: - ApiAddressItem

public struct ApiAddressItem {
    // MARK: Properties

    public let script: String
    public let address: String?

    // MARK: Lifecycle

    public init(script: String, address: String?) {
        self.script = script
        self.address = address
    }
}

// MARK: - ApiBlockHeaderItem

public struct ApiBlockHeaderItem {
    let hash: Data
    let height: Int
    let timestamp: Int
}
