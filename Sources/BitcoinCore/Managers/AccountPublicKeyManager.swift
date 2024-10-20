//
//  AccountPublicKeyManager.swift
//  BitcoinCore
//
//  Created by Sun on 2022/10/17.
//

import Foundation

import HDWalletKit

// MARK: - AccountPublicKeyManager

class AccountPublicKeyManager {
    // MARK: Properties

    weak var bloomFilterManager: IBloomFilterManager?

    private let restoreKeyConverter: IRestoreKeyConverter
    private let storage: IStorage
    private let hdWallet: IHDAccountWallet
    private let gapLimit: Int

    // MARK: Lifecycle

    init(storage: IStorage, hdWallet: IHDAccountWallet, gapLimit: Int, restoreKeyConverter: IRestoreKeyConverter) {
        self.storage = storage
        self.hdWallet = hdWallet
        self.gapLimit = gapLimit
        self.restoreKeyConverter = restoreKeyConverter
    }

    // MARK: Functions

    private func fillGap(publicKeysWithUsedStates: [PublicKeyWithUsedState], external: Bool) throws {
        let publicKeys = publicKeysWithUsedStates.filter { $0.publicKey.external == external }
        let gapKeysCount = gapKeysCount(publicKeyResults: publicKeys)
        var keys = [PublicKey]()

        if gapKeysCount < gapLimit {
            let allKeys = publicKeys.sorted(by: { $0.publicKey.index < $1.publicKey.index })
            let lastIndex = allKeys.last?.publicKey.index ?? -1
            let newKeysStartIndex = lastIndex + 1
            let indices = UInt32(newKeysStartIndex) ..< UInt32(newKeysStartIndex + gapLimit - gapKeysCount)

            keys = try hdWallet.publicKeys(indices: indices, external: external)
        }

        addKeys(keys: keys)
    }

    private func gapKeysCount(publicKeyResults publicKeysWithUsedStates: [PublicKeyWithUsedState]) -> Int {
        if
            let lastUsedKey = publicKeysWithUsedStates.filter(\.used)
                .sorted(by: { $0.publicKey.index < $1.publicKey.index })
                .last {
            publicKeysWithUsedStates.filter { $0.publicKey.index > lastUsedKey.publicKey.index }.count
        } else {
            publicKeysWithUsedStates.count
        }
    }

    private func publicKey(external: Bool) throws -> PublicKey {
        guard
            let unusedKey = storage.publicKeysWithUsedState()
                .filter({ $0.publicKey.external == external && !$0.used })
                .sorted(by: { $0.publicKey.index < $1.publicKey.index })
                .first
        else {
            throw PublicKeyManager.PublicKeyManagerError.noUnusedPublicKey
        }

        return unusedKey.publicKey
    }
}

// MARK: IPublicKeyManager

extension AccountPublicKeyManager: IPublicKeyManager {
    func usedPublicKeys(change: Bool) -> [PublicKey] {
        storage.publicKeysWithUsedState().compactMap { ($0.used && $0.publicKey.external == !change)
            ? $0.publicKey
            : nil
        }
    }

    func changePublicKey() throws -> PublicKey {
        try publicKey(external: false)
    }

    func receivePublicKey() throws -> PublicKey {
        try publicKey(external: true)
    }

    func fillGap() throws {
        let publicKeysWithUsedStates = storage.publicKeysWithUsedState()

        try fillGap(publicKeysWithUsedStates: publicKeysWithUsedStates, external: true)
        try fillGap(publicKeysWithUsedStates: publicKeysWithUsedStates, external: false)

        bloomFilterManager?.regenerateBloomFilter()
    }

    func addKeys(keys: [PublicKey]) {
        guard !keys.isEmpty else {
            return
        }

        storage.add(publicKeys: keys)
    }

    func gapShifts() -> Bool {
        let publicKeysWithUsedStates = storage.publicKeysWithUsedState()

        if gapKeysCount(publicKeyResults: publicKeysWithUsedStates.filter(\.publicKey.external)) < gapLimit {
            return true
        }

        if gapKeysCount(publicKeyResults: publicKeysWithUsedStates.filter { !$0.publicKey.external }) < gapLimit {
            return true
        }

        return false
    }

    public func publicKey(byPath path: String) throws -> PublicKey {
        let parts = path.split(separator: "/")

        guard parts.count == 2, let external = Int(parts[0]), let index = Int(parts[1]) else {
            throw PublicKeyManager.PublicKeyManagerError.invalidPath
        }

        if let publicKey = storage.publicKey(byPath: "0'/\(path)") {
            return publicKey
        }

        return try hdWallet.publicKey(index: index, external: external == 0)
    }
}

// MARK: IBloomFilterProvider

extension AccountPublicKeyManager: IBloomFilterProvider {
    func filterElements() -> [Data] {
        var elements = [Data]()

        for publicKey in storage.publicKeys() {
            elements.append(contentsOf: restoreKeyConverter.bloomFilterElements(publicKey: publicKey))
        }

        return elements
    }
}

extension AccountPublicKeyManager {
    public static func instance(
        storage: IStorage,
        hdWallet: IHDAccountWallet,
        gapLimit: Int,
        restoreKeyConverter: IRestoreKeyConverter
    )
        -> AccountPublicKeyManager {
        let addressManager = AccountPublicKeyManager(
            storage: storage,
            hdWallet: hdWallet,
            gapLimit: gapLimit,
            restoreKeyConverter: restoreKeyConverter
        )
        try? addressManager.fillGap()
        return addressManager
    }
}
