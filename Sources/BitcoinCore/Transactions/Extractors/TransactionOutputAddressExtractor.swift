//
//  TransactionOutputAddressExtractor.swift
//  BitcoinCore
//
//  Created by Sun on 2018/12/17.
//

import Foundation

import SWCryptoKit

// MARK: - TransactionOutputAddressExtractor

class TransactionOutputAddressExtractor {
    // MARK: Properties

    private let storage: IStorage
    private let addressConverter: IAddressConverter

    // MARK: Lifecycle

    init(storage: IStorage, addressConverter: IAddressConverter) {
        self.storage = storage
        self.addressConverter = addressConverter
    }
}

// MARK: ITransactionExtractor

extension TransactionOutputAddressExtractor: ITransactionExtractor {
    public func extract(transaction: FullTransaction) {
        for output in transaction.outputs {
            guard let _payload = output.lockingScriptPayload else {
                continue
            }

            let payload: Data =
                switch output.scriptType {
                case .p2pk:
                    // If the scriptType is P2PK, we generate Address as if it was P2PKH
                    Crypto.ripeMd160Sha256(_payload)
                default: _payload
                }

            let scriptType = output.scriptType
            if let address = try? addressConverter.convert(lockingScriptPayload: payload, type: scriptType) {
                output.address = address.stringValue
            }
        }
    }
}
