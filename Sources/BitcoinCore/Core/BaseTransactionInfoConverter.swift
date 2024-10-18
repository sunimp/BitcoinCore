//
//  BaseTransactionInfoConverter.swift
//  BitcoinCore
//
//  Created by Sun on 2019/5/3.
//

import Foundation

import SWExtensions

// MARK: - IBaseTransactionInfoConverter

public protocol IBaseTransactionInfoConverter {
    func transactionInfo<T: TransactionInfo>(fromTransaction transactionForInfo: FullTransactionForInfo) -> T
}

// MARK: - BaseTransactionInfoConverter

public class BaseTransactionInfoConverter: IBaseTransactionInfoConverter {
    // MARK: Properties

    private let pluginManager: IPluginManager

    // MARK: Lifecycle

    public init(pluginManager: IPluginManager) {
        self.pluginManager = pluginManager
    }

    // MARK: Functions

    public func transactionInfo<T: TransactionInfo>(fromTransaction transactionForInfo: FullTransactionForInfo) -> T {
        if let invalidTransactionInfo: T = transactionInfo(fromInvalidTransaction: transactionForInfo) {
            return invalidTransactionInfo
        }

        var inputsInfo = [TransactionInputInfo]()
        var outputsInfo = [TransactionOutputInfo]()
        let transaction = transactionForInfo.transactionWithBlock.transaction
        let transactionTimestamp = transaction.timestamp

        for inputWithPreviousOutput in transactionForInfo.inputsWithPreviousOutputs {
            var mine = false
            var value: Int? = nil

            if let previousOutput = inputWithPreviousOutput.previousOutput {
                value = previousOutput.value

                if previousOutput.publicKeyPath != nil {
                    mine = true
                }
            }

            inputsInfo.append(TransactionInputInfo(
                mine: mine,
                address: inputWithPreviousOutput.input.address,
                value: value
            ))
        }

        for output in transactionForInfo.outputs {
            let outputInfo = TransactionOutputInfo(
                mine: output.publicKeyPath != nil,
                changeOutput: output.changeOutput,
                value: output.value,
                address: output.address
            )

            if let pluginID = output.pluginID, let pluginDataString = output.pluginData {
                outputInfo.pluginID = pluginID
                outputInfo.pluginDataString = pluginDataString
                outputInfo.pluginData = pluginManager.parsePluginData(
                    fromPlugin: pluginID,
                    pluginDataString: pluginDataString,
                    transactionTimestamp: transactionTimestamp
                )
            } else if let memo = output.memo {
                outputInfo.memo = memo
            }

            outputsInfo.append(outputInfo)
        }

        let rbfEnabled = transactionForInfo.inputsWithPreviousOutputs.contains(where: \.input.rbfEnabled)

        return T(
            uid: transaction.uid,
            transactionHash: transaction.dataHash.sw.reversedHex,
            transactionIndex: transaction.order,
            inputs: inputsInfo,
            outputs: outputsInfo,
            amount: transactionForInfo.metaData.amount,
            type: transactionForInfo.metaData.type,
            fee: transactionForInfo.metaData.fee,
            blockHeight: transactionForInfo.transactionWithBlock.blockHeight,
            timestamp: transactionTimestamp,
            status: transaction.status,
            conflictingHash: transaction.conflictingTxHash?.sw.reversedHex,
            rbfEnabled: rbfEnabled
        )
    }

    private func transactionInfo<T: TransactionInfo>(fromInvalidTransaction transactionForInfo: FullTransactionForInfo)
        -> T? {
        guard let invalidTransaction = transactionForInfo.transactionWithBlock.transaction as? InvalidTransaction else {
            return nil
        }

        guard let transactionInfo: T = try? JSONDecoder().decode(T.self, from: invalidTransaction.transactionInfoJson)
        else {
            return nil
        }

        for addressInfo in transactionInfo.outputs {
            if let pluginID = addressInfo.pluginID, let pluginDataString = addressInfo.pluginDataString {
                addressInfo.pluginData = pluginManager.parsePluginData(
                    fromPlugin: pluginID,
                    pluginDataString: pluginDataString,
                    transactionTimestamp: invalidTransaction.timestamp
                )
            }
        }

        return transactionInfo
    }
}
