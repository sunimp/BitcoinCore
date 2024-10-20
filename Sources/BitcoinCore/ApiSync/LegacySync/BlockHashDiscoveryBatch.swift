//
//  BlockHashDiscoveryBatch.swift
//  BitcoinCore
//
//  Created by Sun on 2019/2/26.
//

import Foundation

import ObjectMapper
import SWToolKit

// MARK: - BlockDiscoveryBatch

class BlockDiscoveryBatch {
    // MARK: Properties

    private let blockHashScanner: BlockHashScanner
    private let publicKeyFetcher: IPublicKeyFetcher

    private let maxHeight: Int
    private let gapLimit: Int

    // MARK: Lifecycle

    init(
        checkpoint: Checkpoint,
        gapLimit: Int,
        blockHashScanner: BlockHashScanner,
        publicKeyFetcher: IPublicKeyFetcher,
        logger _: Logger? = nil
    ) {
        self.blockHashScanner = blockHashScanner
        self.publicKeyFetcher = publicKeyFetcher

        maxHeight = checkpoint.block.height
        self.gapLimit = gapLimit
    }

    // MARK: Functions

    func discoverBlockHashes() async throws -> ([PublicKey], [BlockHash]) {
        try await fetchRecursive()
    }

    private func fetchRecursive(
        blockHashes: [BlockHash] = [],
        externalBatchInfo: KeyBlockHashBatchInfo = KeyBlockHashBatchInfo(),
        internalBatchInfo: KeyBlockHashBatchInfo = KeyBlockHashBatchInfo()
    ) async throws
        -> ([PublicKey], [BlockHash]) {
        let maxHeight = maxHeight

        let externalCount = gapLimit - externalBatchInfo.prevCount + externalBatchInfo.prevLastUsedIndex + 1
        let internalCount = gapLimit - internalBatchInfo.prevCount + internalBatchInfo.prevLastUsedIndex + 1

        var externalNewKeys = [PublicKey]()
        var internalNewKeys = [PublicKey]()

        try externalNewKeys.append(contentsOf: publicKeyFetcher.publicKeys(
            indices: UInt32(externalBatchInfo.startIndex) ..< UInt32(externalBatchInfo.startIndex + externalCount),
            external: true
        ))
        try internalNewKeys.append(contentsOf: publicKeyFetcher.publicKeys(
            indices: UInt32(internalBatchInfo.startIndex) ..< UInt32(internalBatchInfo.startIndex + internalCount),
            external: false
        ))

        let fetcherResponse = try await blockHashScanner.getBlockHashes(
            externalKeys: externalNewKeys,
            internalKeys: internalNewKeys
        )

        let resultBlockHashes = blockHashes + fetcherResponse.blockHashes.filter { $0.height <= maxHeight }
        let externalPublicKeys = externalBatchInfo.publicKeys + externalNewKeys
        let internalPublicKeys = internalBatchInfo.publicKeys + internalNewKeys

        if fetcherResponse.externalLastUsedIndex < 0, fetcherResponse.internalLastUsedIndex < 0 {
            return (externalPublicKeys + internalPublicKeys, resultBlockHashes)
        } else {
            let externalBatch = KeyBlockHashBatchInfo(
                publicKeys: externalPublicKeys,
                prevCount: externalCount,
                prevLastUsedIndex: fetcherResponse.externalLastUsedIndex,
                startIndex: externalBatchInfo.startIndex + externalCount
            )
            let internalBatch = KeyBlockHashBatchInfo(
                publicKeys: internalPublicKeys,
                prevCount: internalCount,
                prevLastUsedIndex: fetcherResponse.internalLastUsedIndex,
                startIndex: internalBatchInfo.startIndex + internalCount
            )

            return try await fetchRecursive(
                blockHashes: resultBlockHashes,
                externalBatchInfo: externalBatch,
                internalBatchInfo: internalBatch
            )
        }
    }
}

// MARK: - KeyBlockHashBatchInfo

class KeyBlockHashBatchInfo {
    // MARK: Properties

    var publicKeys: [PublicKey]
    var prevCount: Int
    var prevLastUsedIndex: Int
    var startIndex: Int

    // MARK: Lifecycle

    init(publicKeys: [PublicKey] = [], prevCount: Int = 0, prevLastUsedIndex: Int = -1, startIndex: Int = 0) {
        self.publicKeys = publicKeys
        self.prevCount = prevCount
        self.prevLastUsedIndex = prevLastUsedIndex
        self.startIndex = startIndex
    }
}
