//
//  PluginManager.swift
//  BitcoinCore
//
//  Created by Sun on 2019/10/9.
//

import Foundation

import SWToolKit

// MARK: - PluginManager

class PluginManager {
    // MARK: Nested Types

    enum PluginError: Error {
        case pluginNotFound
    }

    // MARK: Properties

    private let scriptConverter: IScriptConverter
    private var plugins = [UInt8: IPlugin]()

    private let logger: Logger?

    // MARK: Lifecycle

    init(scriptConverter: IScriptConverter, logger: Logger? = nil) {
        self.scriptConverter = scriptConverter
        self.logger = logger
    }
}

// MARK: IPluginManager

extension PluginManager: IPluginManager {
    func validate(address: Address, pluginData: [UInt8: IPluginData]) throws {
        for (key, _) in pluginData {
            guard let plugin = plugins[key] else {
                throw PluginError.pluginNotFound
            }

            try plugin.validate(address: address)
        }
    }

    func maxSpendLimit(pluginData: [UInt8: IPluginData]) throws -> Int? {
        try pluginData.compactMap { key, _ in
            guard let plugin = plugins[key] else {
                throw PluginError.pluginNotFound
            }

            return plugin.maxSpendLimit
        }.min()
    }

    func add(plugin: IPlugin) {
        plugins[plugin.id] = plugin
    }

    func processOutputs(
        mutableTransaction: MutableTransaction,
        pluginData: [UInt8: IPluginData],
        skipChecks: Bool = false
    ) throws {
        for (key, data) in pluginData {
            guard let plugin = plugins[key] else {
                throw PluginError.pluginNotFound
            }

            try plugin.processOutputs(mutableTransaction: mutableTransaction, pluginData: data, skipChecks: skipChecks)
        }
    }

    func processInputs(mutableTransaction: MutableTransaction) throws {
        for inputToSign in mutableTransaction.inputsToSign {
            guard let pluginID = inputToSign.previousOutput.pluginID else {
                continue
            }

            guard let plugin = plugins[pluginID] else {
                throw PluginError.pluginNotFound
            }

            inputToSign.input.sequence = try plugin.inputSequenceNumber(output: inputToSign.previousOutput)
        }
    }

    func processTransactionWithNullData(transaction: FullTransaction, nullDataOutput: Output) throws {
        guard let script = try? scriptConverter.decode(data: nullDataOutput.lockingScript) else {
            return
        }

        var iterator = script.chunks.makeIterator()

        // the first byte OP_RETURN
        _ = iterator.next()

        do {
            while let pluginID = iterator.next() {
                guard let plugin = plugins[pluginID.opCode] else {
                    break
                }

                try plugin.processTransactionWithNullData(transaction: transaction, nullDataChunks: &iterator)
            }
        } catch {
            logger?.error(error)
        }
    }

    func isSpendable(unspentOutput: UnspentOutput) -> Bool {
        guard let pluginID = unspentOutput.output.pluginID else {
            return true
        }

        guard let plugin = plugins[pluginID] else {
            return false
        }

        return (try? plugin.isSpendable(unspentOutput: unspentOutput)) ?? true
    }

    public func parsePluginData(
        fromPlugin pluginID: UInt8,
        pluginDataString: String,
        transactionTimestamp: Int
    )
        -> IPluginOutputData? {
        guard let plugin = plugins[pluginID] else {
            return nil
        }

        return try? plugin.parsePluginData(from: pluginDataString, transactionTimestamp: transactionTimestamp)
    }

    public func incrementedSequence(of inputWithPreviousOutput: InputWithPreviousOutput) -> Int {
        guard
            let pluginID = inputWithPreviousOutput.previousOutput?.pluginID,
            let plugin = plugins[pluginID]
        else {
            return inputWithPreviousOutput.input.sequence + 1
        }

        return plugin.incrementSequence(sequence: inputWithPreviousOutput.input.sequence)
    }
}
