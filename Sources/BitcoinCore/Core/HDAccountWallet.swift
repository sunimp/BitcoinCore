//
//  HDAccountWallet.swift
//  BitcoinCore
//
//  Created by Sun on 2022/10/17.
//

import Foundation

import HDWalletKit

// MARK: - IHDAccountWallet

protocol IHDAccountWallet {
    func publicKey(index: Int, external: Bool) throws -> PublicKey
    func publicKeys(indices: Range<UInt32>, external: Bool) throws -> [PublicKey]
}

// MARK: - HDAccountWallet + IHDAccountWallet

extension HDAccountWallet: IHDAccountWallet {
    func publicKey(index: Int, external: Bool) throws -> PublicKey {
        try PublicKey(
            withAccount: 0,
            index: index,
            external: external,
            hdPublicKeyData: publicKey(index: index, chain: external ? .external : .internal).raw
        )
    }

    func publicKeys(indices: Range<UInt32>, external: Bool) throws -> [PublicKey] {
        let hdPublicKeys: [HDPublicKey] = try publicKeys(indices: indices, chain: external ? .external : .internal)

        guard hdPublicKeys.count == indices.count else {
            throw HDWallet.HDWalletError.publicKeysDerivationFailed
        }

        return try indices.map { index in
            let key = hdPublicKeys[Int(index - indices.lowerBound)]
            return try PublicKey(withAccount: 0, index: Int(index), external: external, hdPublicKeyData: key.raw)
        }
    }
}

// MARK: - HDAccountWallet + IPrivateHDWallet

extension HDAccountWallet: IPrivateHDWallet {
    func privateKeyData(
        account _: Int,
        index: Int,
        external: Bool
    ) throws
        -> Data { // todo. Refactor protocol. Because HDWallet and HDAccountWallet use different fields for derive
        try privateKey(index: index, chain: external ? .external : .internal).raw
    }
}
