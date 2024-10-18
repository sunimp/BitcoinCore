//
//  TransactionBuilder.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/9.
//

import Foundation

// MARK: - TransactionBuilder

class TransactionBuilder {
    // MARK: Properties

    private let recipientSetter: IRecipientSetter
    private let inputSetter: IInputSetter
    private let lockTimeSetter: ILockTimeSetter
    private let outputSetter: IOutputSetter

    // MARK: Lifecycle

    init(
        recipientSetter: IRecipientSetter,
        inputSetter: IInputSetter,
        lockTimeSetter: ILockTimeSetter,
        outputSetter: IOutputSetter
    ) {
        self.recipientSetter = recipientSetter
        self.inputSetter = inputSetter
        self.lockTimeSetter = lockTimeSetter
        self.outputSetter = outputSetter
    }
}

// MARK: ITransactionBuilder

extension TransactionBuilder: ITransactionBuilder {
    func buildTransaction(params: SendParameters) throws -> MutableTransaction {
        let mutableTransaction = MutableTransaction()

        try recipientSetter.setRecipient(to: mutableTransaction, params: params, skipChecks: false)
        try inputSetter.setInputs(to: mutableTransaction, params: params)
        lockTimeSetter.setLockTime(to: mutableTransaction)
        outputSetter.setOutputs(to: mutableTransaction, sortType: params.sortType)

        return mutableTransaction
    }

    func buildTransaction(from unspentOutput: UnspentOutput, params: SendParameters) throws -> MutableTransaction {
        let mutableTransaction = MutableTransaction(outgoing: false)
        params.value = unspentOutput.output.value

        try recipientSetter.setRecipient(to: mutableTransaction, params: params, skipChecks: false)
        try inputSetter.setInputs(to: mutableTransaction, fromUnspentOutput: unspentOutput, params: params)
        lockTimeSetter.setLockTime(to: mutableTransaction)

        outputSetter.setOutputs(to: mutableTransaction, sortType: params.sortType)

        return mutableTransaction
    }
}
