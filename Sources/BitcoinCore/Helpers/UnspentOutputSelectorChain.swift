//
//  UnspentOutputSelectorChain.swift
//  BitcoinCore
//
//  Created by Sun on 2019/5/7.
//

import Foundation

class UnspentOutputSelectorChain: IUnspentOutputSelector {
    // MARK: Properties

    var concreteSelectors = [IUnspentOutputSelector]()

    private let provider: IUnspentOutputProvider

    // MARK: Lifecycle

    init(provider: IUnspentOutputProvider) {
        self.provider = provider
    }

    // MARK: Functions

    public func all(filters: UtxoFilters) -> [UnspentOutput] {
        provider.spendableUtxo(filters: filters)
    }

    func select(
        params: SendParameters,
        outputScriptType: ScriptType,
        changeType: ScriptType,
        pluginDataOutputSize: Int
    ) throws
        -> SelectedUnspentOutputInfo {
        var lastError: Error = BitcoinCoreErrors.Unexpected.unknown

        for selector in concreteSelectors {
            do {
                return try selector.select(
                    params: params,
                    outputScriptType: outputScriptType,
                    changeType: changeType,
                    pluginDataOutputSize: pluginDataOutputSize
                )
            } catch {
                lastError = error
            }
        }

        throw lastError
    }

    func prepend(unspentOutputSelector: IUnspentOutputSelector) {
        concreteSelectors.insert(unspentOutputSelector, at: 0)
    }
}
