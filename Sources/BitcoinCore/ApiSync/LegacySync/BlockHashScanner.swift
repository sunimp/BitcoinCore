//
//  BlockHashScanner.swift
//  BitcoinCore
//
//  Created by Sun on 2019/2/26.
//

import Foundation

// MARK: - BlockHashScanner

class BlockHashScanner {
    // MARK: Properties

    weak var listener: IApiSyncerListener?

    private let restoreKeyConverter: IRestoreKeyConverter
    private let provider: IApiTransactionProvider
    private let helper: IBlockHashScanHelper

    // MARK: Lifecycle

    init(restoreKeyConverter: IRestoreKeyConverter, provider: IApiTransactionProvider, helper: IBlockHashScanHelper) {
        self.restoreKeyConverter = restoreKeyConverter
        self.provider = provider
        self.helper = helper
    }

    // MARK: Functions

    func getBlockHashes(externalKeys: [PublicKey], internalKeys: [PublicKey]) async throws -> BlockHashesResponse {
        let externalAddresses = externalKeys.map {
            restoreKeyConverter.keysForApiRestore(publicKey: $0)
        }

        let internalAddresses = internalKeys.map {
            restoreKeyConverter.keysForApiRestore(publicKey: $0)
        }

        let allAddresses = externalAddresses.flatMap { $0 } + internalAddresses.flatMap { $0 }
        let transactionResponses = try await provider.transactions(addresses: allAddresses, stopHeight: nil)

        if transactionResponses.isEmpty {
            return BlockHashesResponse(blockHashes: [], externalLastUsedIndex: -1, internalLastUsedIndex: -1)
        }

        listener?.transactionsFound(count: transactionResponses.count)

        let outputs = transactionResponses.flatMap(\.apiAddressItems)
        let externalLastUsedIndex = helper.lastUsedIndex(addresses: externalAddresses, items: outputs)
        let internalLastUsedIndex = helper.lastUsedIndex(addresses: internalAddresses, items: outputs)

        let blockHashes: [BlockHash] = transactionResponses.compactMap {
            BlockHash(headerHashReversedHex: $0.blockHash, height: $0.blockHeight, sequence: 0)
        }

        return BlockHashesResponse(
            blockHashes: blockHashes,
            externalLastUsedIndex: externalLastUsedIndex,
            internalLastUsedIndex: internalLastUsedIndex
        )
    }
}

// MARK: - BlockHashesResponse

struct BlockHashesResponse {
    let blockHashes: [BlockHash]
    let externalLastUsedIndex: Int
    let internalLastUsedIndex: Int
}
