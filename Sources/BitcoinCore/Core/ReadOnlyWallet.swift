//
//  ReadOnlyWallet.swift
//  BitcoinCore
//
//  Created by Sun on 2022/4/7.
//

import Foundation

import HDWalletKit

// MARK: - ReadOnlyWallet

class ReadOnlyWallet {
    // MARK: Nested Types

    enum ReadOnlyWalletError: Error {
        case noKeyForGivenAccount
        case publicKeysDerivationFailed
    }

    // MARK: Properties

    var gapLimit: Int

    private let keys: [Int: String] // [accountId: extendedPublicKey]

    // MARK: Lifecycle

    init(keys: [Int: String], gapLimit: Int) {
        self.keys = keys
        self.gapLimit = gapLimit
    }
}

// MARK: IHDWallet

extension ReadOnlyWallet: IHDWallet {
    func publicKey(account: Int, index: Int, external: Bool) throws -> PublicKey {
        try publicKeys(account: account, indices: UInt32(index) ..< UInt32(index + 1), external: external).first!
    }

    func publicKeys(account: Int, indices: Range<UInt32>, external: Bool) throws -> [PublicKey] {
        guard let key = keys[account] else {
            throw ReadOnlyWalletError.noKeyForGivenAccount
        }

        let hdPublicKeys: [HDPublicKey] = try ReadOnlyHDWallet.publicKeys(
            extendedPublicKey: key,
            indices: indices,
            chain: external ? .external : .internal
        )

        guard hdPublicKeys.count == indices.count else {
            throw ReadOnlyWalletError.publicKeysDerivationFailed
        }

        return try indices.map { index in
            let key = hdPublicKeys[Int(index - indices.lowerBound)]
            return try PublicKey(withAccount: account, index: Int(index), external: external, hdPublicKeyData: key.raw)
        }
    }
}
