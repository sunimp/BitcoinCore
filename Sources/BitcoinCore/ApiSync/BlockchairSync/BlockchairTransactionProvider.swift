//
//  BlockchairTransactionProvider.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

public class BlockchairTransactionProvider: IApiTransactionProvider {
    // MARK: Properties

    let blockchairApi: BlockchairApi

    private let blockHashFetcher: IBlockHashFetcher

    // MARK: Lifecycle

    public init(blockchairApi: BlockchairApi, blockHashFetcher: IBlockHashFetcher) {
        self.blockchairApi = blockchairApi
        self.blockHashFetcher = blockHashFetcher
    }

    // MARK: Functions

    public func transactions(addresses: [String], stopHeight: Int?) async throws -> [ApiTransactionItem] {
        let items = try await blockchairApi.transactions(addresses: addresses, stopHeight: stopHeight)

        return try await fillBlockHashes(items: items)
    }

    private func fillBlockHashes(items: [ApiTransactionItem]) async throws -> [ApiTransactionItem] {
        let hashesMap = try await blockHashFetcher.fetch(heights: items.map(\.blockHeight))

        return items.compactMap { item -> ApiTransactionItem? in
            guard let blockHash = hashesMap[item.blockHeight] else {
                return nil
            }

            return ApiTransactionItem(
                blockHash: blockHash,
                blockHeight: item.blockHeight,
                apiAddressItems: item.apiAddressItems
            )
        }
    }
}
