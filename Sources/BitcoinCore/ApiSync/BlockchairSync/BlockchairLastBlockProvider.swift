//
//  BlockchairLastBlockProvider.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

public class BlockchairLastBlockProvider {
    // MARK: Properties

    private let blockchairApi: BlockchairApi

    // MARK: Lifecycle

    public init(blockchairApi: BlockchairApi) {
        self.blockchairApi = blockchairApi
    }

    // MARK: Functions

    public func lastBlockHeader() async throws -> ApiBlockHeaderItem {
        try await blockchairApi.lastBlockHeader()
    }
}
