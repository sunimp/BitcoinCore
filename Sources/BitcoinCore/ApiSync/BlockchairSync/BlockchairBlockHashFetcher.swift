//
//  BlockchairBlockHashFetcher.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

public class BlockchairBlockHashFetcher: IBlockHashFetcher {
    // MARK: Properties

    private let blockchairApi: BlockchairApi

    // MARK: Lifecycle

    public init(blockchairApi: BlockchairApi) {
        self.blockchairApi = blockchairApi
    }

    // MARK: Functions

    public func fetch(heights: [Int]) async throws -> [Int: String] {
        try await blockchairApi.blockHashes(heights: heights)
    }
}
