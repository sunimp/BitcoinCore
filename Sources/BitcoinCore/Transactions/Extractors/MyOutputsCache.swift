//
//  MyOutputsCache.swift
//  BitcoinCore
//
//  Created by Sun on 2021/9/3.
//

import Foundation

// MARK: - MyOutputsCache

class MyOutputsCache {
    private var outputs = [Data: [Int: Int]]() // [TxHash: [OutputIndex: OutputValue]]
}

// MARK: IOutputsCache

extension MyOutputsCache: IOutputsCache {
    func add(outputs: [Output]) {
        for output in outputs {
            if output.publicKeyPath != nil {
                if self.outputs[output.transactionHash] != nil {
                    self.outputs[output.transactionHash]?[output.index] = output.value
                } else {
                    self.outputs[output.transactionHash] = [output.index: output.value]
                }
            }
        }
    }

    func valueSpent(by input: Input) -> Int? {
        outputs[input.previousOutputTxHash]?[input.previousOutputIndex]
    }

    func clear() {
        outputs.removeAll()
    }
}

extension MyOutputsCache {
    static func instance(storage: IOutputStorage) -> MyOutputsCache {
        let instance = MyOutputsCache()
        let outputs = storage.outputsWithPublicKeys()
        instance.add(outputs: outputs.map(\.output))

        return instance
    }
}
