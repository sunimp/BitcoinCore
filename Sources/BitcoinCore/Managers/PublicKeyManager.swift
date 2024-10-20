//
//  PublicKeyManager.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/28.
//

import Foundation

import HDWalletKit

// MARK: - PublicKeyManager

class PublicKeyManager {
    // MARK: Nested Types

    enum PublicKeyManagerError: Error {
        case noUnusedPublicKey
        case invalidPath
    }

    // MARK: Properties

    weak var bloomFilterManager: IBloomFilterManager?

    private let restoreKeyConverter: IRestoreKeyConverter
    private let storage: IStorage
    private let hdWallet: HDWallet
    private let gapLimit: Int

    // MARK: Lifecycle

    init(storage: IStorage, hdWallet: HDWallet, gapLimit: Int, restoreKeyConverter: IRestoreKeyConverter) {
        self.storage = storage
        self.hdWallet = hdWallet
        self.gapLimit = gapLimit
        self.restoreKeyConverter = restoreKeyConverter
    }

    // MARK: Functions

    private func fillGap(publicKeysWithUsedStates: [PublicKeyWithUsedState], account: Int, external: Bool) throws {
        let publicKeys = publicKeysWithUsedStates
            .filter { $0.publicKey.account == account && $0.publicKey.external == external }
        let gapKeysCount = gapKeysCount(publicKeyResults: publicKeys)
        var keys = [PublicKey]()

        if gapKeysCount < gapLimit {
            let allKeys = publicKeys.sorted(by: { $0.publicKey.index < $1.publicKey.index })
            let lastIndex = allKeys.last?.publicKey.index ?? -1
            let newKeysStartIndex = lastIndex + 1
            let indices = UInt32(newKeysStartIndex) ..< UInt32(newKeysStartIndex + gapLimit - gapKeysCount)

            keys = try hdWallet.publicKeys(account: account, indices: indices, external: external)
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
                .filter({ $0.publicKey.external == external && $0.publicKey.account == 0 && !$0.used })
                .sorted(by: { $0.publicKey.index < $1.publicKey.index })
                .first
        else {
            throw PublicKeyManagerError.noUnusedPublicKey
        }

        return unusedKey.publicKey
    }
}

// MARK: IPublicKeyManager

extension PublicKeyManager: IPublicKeyManager {
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
        let requiredAccountsCount: Int =
            if
                let lastUsedAccount = publicKeysWithUsedStates.filter(\.used)
                    .sorted(by: { $0.publicKey.account < $1.publicKey.account }).last?.publicKey.account {
                lastUsedAccount + 1 + 1 // One because account starts from 0, One because we must have n+1 accounts
            } else {
                1
            }

        for i in 0 ..< requiredAccountsCount {
            try fillGap(publicKeysWithUsedStates: publicKeysWithUsedStates, account: i, external: true)
            try fillGap(publicKeysWithUsedStates: publicKeysWithUsedStates, account: i, external: false)
        }

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

        guard
            let lastAccount = publicKeysWithUsedStates.sorted(by: { $0.publicKey.account < $1.publicKey.account }).last?
                .publicKey.account
        else {
            return false
        }

        for i in 0 ..< (lastAccount + 1) {
            if
                gapKeysCount(
                    publicKeyResults: publicKeysWithUsedStates
                        .filter { $0.publicKey.account == i && $0.publicKey.external }
                ) < gapLimit {
                return true
            }

            if
                gapKeysCount(
                    publicKeyResults: publicKeysWithUsedStates
                        .filter { $0.publicKey.account == i && !$0.publicKey.external }
                ) < gapLimit {
                return true
            }
        }

        return false
    }

    public func publicKey(byPath path: String) throws -> PublicKey {
        let parts = path.split(separator: "/")

        guard
            parts.count == 3, let account = Int(parts[0]), let external = Int(parts[1]),
            let index = Int(parts[2])
        else {
            throw PublicKeyManagerError.invalidPath
        }

        if let publicKey = storage.publicKey(byPath: path) {
            return publicKey
        }

        return try hdWallet.publicKey(account: account, index: index, external: external == 0)
    }
}

// MARK: IBloomFilterProvider

extension PublicKeyManager: IBloomFilterProvider {
    func filterElements() -> [Data] {
        var elements = [Data]()

        for publicKey in storage.publicKeys() {
            elements.append(contentsOf: restoreKeyConverter.bloomFilterElements(publicKey: publicKey))
        }

        return elements
    }
}

extension PublicKeyManager {
    public static func instance(
        storage: IStorage,
        hdWallet: HDWallet,
        gapLimit: Int,
        restoreKeyConverter: IRestoreKeyConverter
    )
        -> PublicKeyManager {
        let addressManager = PublicKeyManager(
            storage: storage,
            hdWallet: hdWallet,
            gapLimit: gapLimit,
            restoreKeyConverter: restoreKeyConverter
        )
        try? addressManager.fillGap()
        return addressManager
    }
}
