//
//  ApiSyncer.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/23.
//

import Foundation

import HDWalletKit
import SWExtensions
import SWToolKit

// MARK: - IMultiAccountPublicKeyFetcher

protocol IMultiAccountPublicKeyFetcher {
    var currentAccount: Int { get }
    func increaseAccount()
}

// MARK: - ApiSyncer

class ApiSyncer {
    // MARK: Properties

    weak var listener: IApiSyncerListener?

    private var tasks = Set<AnyTask>()

    private let storage: IStorage
    private let blockDiscovery: BlockDiscoveryBatch
    private let publicKeyManager: IPublicKeyManager
    private let multiAccountPublicKeyFetcher: IMultiAccountPublicKeyFetcher?
    private let apiSyncStateManager: ApiSyncStateManager

    private let logger: Logger?

    // MARK: Lifecycle

    init(
        storage: IStorage,
        blockDiscovery: BlockDiscoveryBatch,
        publicKeyManager: IPublicKeyManager,
        multiAccountPublicKeyFetcher: IMultiAccountPublicKeyFetcher?,
        apiSyncStateManager: ApiSyncStateManager,
        logger: Logger? = nil
    ) {
        self.storage = storage
        self.blockDiscovery = blockDiscovery
        self.publicKeyManager = publicKeyManager
        self.multiAccountPublicKeyFetcher = multiAccountPublicKeyFetcher
        self.apiSyncStateManager = apiSyncStateManager

        self.logger = logger
    }

    // MARK: Functions

    private func _sync() async {
        do {
            let array = try await blockDiscovery.discoverBlockHashes()

            let (keys, blockHashes) = array
            let sortedUniqueBlockHashes = blockHashes.unique.sorted { a, b in a.height < b.height }

            handle(keys: keys, blockHashes: sortedUniqueBlockHashes)
        } catch {
            handle(error: error)
        }
    }

    private func handle(keys: [PublicKey], blockHashes: [BlockHash]) {
        var log = ""
        if let account = multiAccountPublicKeyFetcher?.currentAccount {
            log += "Account: \(account) "
        } else {
            log += "Base account "
        }
        log += "has \(keys.count) keys and \(blockHashes.count) blocks"
        logger?.debug(log)
        publicKeyManager.addKeys(keys: keys)

        // If gap shift is found
        if let multiAccountFetcher = multiAccountPublicKeyFetcher {
            if blockHashes.isEmpty {
                handleSuccess()
            } else {
                // add hashes, increase and check next account
                storage.add(blockHashes: blockHashes)
                multiAccountFetcher.increaseAccount()
                sync()
            }
        } else {
            // just add hashes and finish
            storage.add(blockHashes: blockHashes)
            handleSuccess()
        }
    }

    private func handleSuccess() {
        apiSyncStateManager.restored = true
        listener?.onSyncSuccess()
    }

    private func handle(error: Error) {
        logger?.error(error, context: ["apiSync"], save: true)
        listener?.onSyncFailed(error: error)
    }
}

// MARK: IApiSyncer

extension ApiSyncer: IApiSyncer {
    var willSync: Bool {
        !apiSyncStateManager.restored
    }

    func sync() {
        Task { [weak self] in await self?._sync() }.store(in: &tasks)
    }

    func terminate() {
        tasks = Set()
    }
}
