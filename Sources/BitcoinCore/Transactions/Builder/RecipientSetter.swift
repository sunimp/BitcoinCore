//
//  RecipientSetter.swift
//  BitcoinCore
//
//  Created by Sun on 2019/10/4.
//

import Foundation

// MARK: - RecipientSetter

class RecipientSetter {
    // MARK: Properties

    private let addressConverter: IAddressConverter
    private let pluginManager: IPluginManager

    // MARK: Lifecycle

    init(addressConverter: IAddressConverter, pluginManager: IPluginManager) {
        self.addressConverter = addressConverter
        self.pluginManager = pluginManager
    }
}

// MARK: IRecipientSetter

extension RecipientSetter: IRecipientSetter {
    func setRecipient(
        to mutableTransaction: MutableTransaction,
        params: SendParameters,
        skipChecks: Bool = false
    ) throws {
        guard let address = params.address, let value = params.value else {
            throw BitcoinCoreErrors.TransactionSendError.invalidParameters
        }

        mutableTransaction.recipientAddress = try addressConverter.convert(address: address)
        mutableTransaction.recipientValue = value
        mutableTransaction.memo = params.memo

        try pluginManager.processOutputs(
            mutableTransaction: mutableTransaction,
            pluginData: params.pluginData,
            skipChecks: skipChecks
        )
    }
}
