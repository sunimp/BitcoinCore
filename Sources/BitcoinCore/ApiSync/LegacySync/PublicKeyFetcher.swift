//
//  PublicKeyFetcher.swift
//  BitcoinCore
//
//  Created by Sun on 2022/10/17.
//

import Foundation

import HDWalletKit

// MARK: - PublicKeyFetcher

class PublicKeyFetcher {
    // MARK: Properties

    private let hdAccountWallet: HDAccountWallet

    // MARK: Lifecycle

    init(hdAccountWallet: HDAccountWallet) {
        self.hdAccountWallet = hdAccountWallet
    }
}

// MARK: IPublicKeyFetcher

extension PublicKeyFetcher: IPublicKeyFetcher {
    func publicKeys(indices: Range<UInt32>, external: Bool) throws -> [PublicKey] {
        try hdAccountWallet.publicKeys(indices: indices, external: external)
    }
}

// MARK: - WatchPublicKeyFetcher

class WatchPublicKeyFetcher {
    // MARK: Properties

    private let hdWatchAccountWallet: HDWatchAccountWallet

    // MARK: Lifecycle

    init(hdWatchAccountWallet: HDWatchAccountWallet) {
        self.hdWatchAccountWallet = hdWatchAccountWallet
    }
}

// MARK: IPublicKeyFetcher

extension WatchPublicKeyFetcher: IPublicKeyFetcher {
    func publicKeys(indices: Range<UInt32>, external: Bool) throws -> [PublicKey] {
        try hdWatchAccountWallet.publicKeys(indices: indices, external: external)
    }
}

// MARK: - MultiAccountPublicKeyFetcher

class MultiAccountPublicKeyFetcher {
    // MARK: Properties

    private(set) var currentAccount = 0

    private let hdWallet: HDWallet

    // MARK: Lifecycle

    init(hdWallet: HDWallet) {
        self.hdWallet = hdWallet
    }
}

// MARK: IPublicKeyFetcher, IMultiAccountPublicKeyFetcher

extension MultiAccountPublicKeyFetcher: IPublicKeyFetcher, IMultiAccountPublicKeyFetcher {
    func publicKeys(indices: Range<UInt32>, external: Bool) throws -> [PublicKey] {
        try hdWallet.publicKeys(account: currentAccount, indices: indices, external: external)
    }

    func increaseAccount() {
        currentAccount += 1
    }
}
