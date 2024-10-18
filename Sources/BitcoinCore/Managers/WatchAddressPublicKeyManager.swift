//
//  WatchAddressPublicKeyManager.swift
//  BitcoinCore
//
//  Created by Sun on 2023/11/22.
//

import Foundation

class WatchAddressPublicKeyManager: IPublicKeyFetcher, IPublicKeyManager, IBloomFilterProvider {
    // MARK: Properties

    weak var bloomFilterManager: IBloomFilterManager?

    private let publicKey: WatchAddressPublicKey
    private let restoreKeyConverter: RestoreKeyConverterChain

    // MARK: Lifecycle

    init(storage: IStorage, publicKey: WatchAddressPublicKey, restoreKeyConverter: RestoreKeyConverterChain) {
        self.publicKey = publicKey
        self.restoreKeyConverter = restoreKeyConverter

        if !storage.publicKeys().contains(where: { $0.path == publicKey.path }) {
            storage.add(publicKeys: [publicKey])
        }
    }

    // MARK: Functions

    func publicKeys(indices _: Range<UInt32>, external _: Bool) throws -> [PublicKey] {
        [publicKey]
    }

    func changePublicKey() throws -> PublicKey {
        publicKey
    }

    func receivePublicKey() throws -> PublicKey {
        publicKey
    }

    func usedPublicKeys(change _: Bool) -> [PublicKey] {
        []
    }

    func fillGap() throws {
        bloomFilterManager?.regenerateBloomFilter()
    }

    func addKeys(keys _: [PublicKey]) { }

    func gapShifts() -> Bool {
        false
    }

    func publicKey(byPath _: String) throws -> PublicKey {
        throw PublicKeyManager.PublicKeyManagerError.invalidPath
    }

    func filterElements() -> [Data] {
        restoreKeyConverter.bloomFilterElements(publicKey: publicKey)
    }
}
