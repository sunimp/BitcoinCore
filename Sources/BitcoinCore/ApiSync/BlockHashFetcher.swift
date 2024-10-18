//
//  BlockHashFetcher.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

public class BlockHashFetcher: IBlockHashFetcher {
    // MARK: Properties

    private let wwFetcher: SWBlockHashFetcher
    private let blockchairFetcher: BlockchairBlockHashFetcher
    private let checkpointHeight: Int

    // MARK: Lifecycle

    public init(wwFetcher: SWBlockHashFetcher, blockchairFetcher: BlockchairBlockHashFetcher, checkpointHeight: Int) {
        self.wwFetcher = wwFetcher
        self.blockchairFetcher = blockchairFetcher
        self.checkpointHeight = checkpointHeight
    }

    // MARK: Functions

    public func fetch(heights: [Int]) async throws -> [Int: String] {
        let sorted = heights.sorted()
        let beforeCheckpoint = sorted.filter { $0 <= checkpointHeight }
        let afterCheckpoint = Array(sorted.suffix(sorted.count - beforeCheckpoint.count))

        var blockHashes = [Int: String]()

        if !beforeCheckpoint.isEmpty {
            blockHashes = try await wwFetcher.fetch(heights: beforeCheckpoint)
        }

        if !afterCheckpoint.isEmpty {
            try await blockHashes.merge(
                blockchairFetcher.fetch(heights: afterCheckpoint),
                uniquingKeysWith: { a, _ in a }
            )
        }

        return blockHashes
    }
}
