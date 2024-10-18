//
//  TransactionFeeCalculator.swift
//  BitcoinCore
//
//  Created by Sun on 2019/9/11.
//

import Foundation

// MARK: - TransactionFeeCalculator

class TransactionFeeCalculator {
    // MARK: Properties

    private let recipientSetter: IRecipientSetter
    private let inputSetter: IInputSetter
    private let changeScriptType: ScriptType

    // MARK: Lifecycle

    init(recipientSetter: IRecipientSetter, inputSetter: IInputSetter, changeScriptType: ScriptType) {
        self.recipientSetter = recipientSetter
        self.inputSetter = inputSetter
        self.changeScriptType = changeScriptType
    }
}

// MARK: ITransactionFeeCalculator

extension TransactionFeeCalculator: ITransactionFeeCalculator {
    func sendInfo(params: SendParameters) throws -> BitcoinSendInfo {
        let mutableTransaction = MutableTransaction()

        try recipientSetter.setRecipient(to: mutableTransaction, params: params, skipChecks: true)
        let outputInfo = try inputSetter.setInputs(to: mutableTransaction, params: params)

        let inputsTotalValue = mutableTransaction.inputsToSign
            .reduce(0) { total, input in total + input.previousOutput.value }
        let outputsTotalValue = mutableTransaction.recipientValue + mutableTransaction.changeValue

        return BitcoinSendInfo(
            unspentOutputs: outputInfo.unspentOutputs,
            fee: inputsTotalValue - outputsTotalValue,
            changeValue: outputInfo.changeInfo?.value,
            changeAddress: outputInfo.changeInfo?.address
        )
    }
}
