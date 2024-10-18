//
//  MutableTransaction.swift
//  BitcoinCore
//
//  Created by Sun on 2019/10/4.
//

import Foundation

public class MutableTransaction {
    // MARK: Properties

    public var recipientAddress: Address!
    public var recipientValue = 0

    var transaction = Transaction(version: 2, lockTime: 0)
    var inputsToSign = [InputToSign]()
    var outputs = [Output]()

    var memo: String?
    var changeAddress: Address?
    var changeValue = 0

    private(set) var pluginData = [UInt8: Data]()

    // MARK: Computed Properties

    var pluginDataOutputSize: Int {
        !pluginData.isEmpty ? 1 + pluginData
            .reduce(into: 0) { $0 += 1 + $1.value.count } : 0 // OP_RETURN (PLUGIN_ID PLUGIN_DATA)
    }

    // MARK: Lifecycle

    public init(outgoing: Bool = true) {
        transaction.status = .new
        transaction.isMine = true
        transaction.isOutgoing = outgoing
    }

    // MARK: Functions

    public func add(pluginData: Data, pluginID: UInt8) {
        self.pluginData[pluginID] = pluginData
    }

    public func build() -> FullTransaction {
        FullTransaction(header: transaction, inputs: inputsToSign.map(\.input), outputs: outputs)
    }

    func add(inputToSign: InputToSign) {
        inputsToSign.append(inputToSign)
    }
}
