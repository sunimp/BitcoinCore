//
//  Bip69.swift
//  BitcoinCore
//
//  Created by Sun on 2020/1/15.
//

import Foundation

enum Bip69 {
    // MARK: Static Properties

    static var outputComparator: ((Output, Output) -> Bool) = { o, o1 in
        if o.value != o1.value {
            return o.value < o1.value
        }

        guard let lsp1 = o.lockingScriptPayload else {
            return false
        }
        guard let lsp2 = o1.lockingScriptPayload else {
            return true
        }

        return compare(data: lsp1, data2: lsp2)
    }

    static var inputComparator: ((UnspentOutput, UnspentOutput) -> Bool) = { o, o1 in
        let result = Bip69.compare(data: o.output.transactionHash, data2: o1.output.transactionHash)

        return result || o.output.index < o1.output.index
    }

    // MARK: Static Functions

    private static func compare(data: Data, data2: Data) -> Bool {
        guard data.count == data2.count else {
            return data.count < data2.count
        }

        let count = data.count
        for index in 0 ..< count {
            if data[index] == data2[index] {
                continue
            } else {
                return data[index] < data2[index]
            }
        }
        return false
    }
}
