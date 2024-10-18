//
//  InfoObjects.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/11.
//

import Foundation

// MARK: - TransactionInfo

open class TransactionInfo: ITransactionInfo, Codable {
    // MARK: Properties

    public let uid: String
    public let transactionHash: String
    public let transactionIndex: Int
    public let inputs: [TransactionInputInfo]
    public let outputs: [TransactionOutputInfo]
    public let amount: Int
    public let type: TransactionType
    public let fee: Int?
    public let blockHeight: Int?
    public let timestamp: Int
    public let status: TransactionStatus
    public let conflictingHash: String?
    public let rbfEnabled: Bool

    // MARK: Computed Properties

    public var replaceable: Bool {
        // Here we can't check wether there are conflicting transactions in state "new", so this flag must be used with
        // caution.
        rbfEnabled && blockHeight == nil && conflictingHash == nil
    }

    // MARK: Lifecycle

    public required init(
        uid: String,
        transactionHash: String,
        transactionIndex: Int,
        inputs: [TransactionInputInfo],
        outputs: [TransactionOutputInfo],
        amount: Int,
        type: TransactionType,
        fee: Int?,
        blockHeight: Int?,
        timestamp: Int,
        status: TransactionStatus,
        conflictingHash: String?,
        rbfEnabled: Bool
    ) {
        self.uid = uid
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.inputs = inputs
        self.outputs = outputs
        self.amount = amount
        self.type = type
        self.fee = fee
        self.blockHeight = blockHeight
        self.timestamp = timestamp
        self.status = status
        self.conflictingHash = conflictingHash
        self.rbfEnabled = rbfEnabled
    }
}

// MARK: - TransactionInputInfo

public class TransactionInputInfo: Codable {
    // MARK: Properties

    public let mine: Bool
    public let address: String?
    public let value: Int?

    // MARK: Lifecycle

    public init(mine: Bool, address: String?, value: Int?) {
        self.mine = mine
        self.address = address
        self.value = value
    }
}

// MARK: - TransactionOutputInfo

public class TransactionOutputInfo: Codable {
    // MARK: Nested Types

    private enum CodingKeys: String, CodingKey {
        case mine
        case changeOutput
        case value
        case address
        case pluginID
        case pluginDataString
    }

    // MARK: Properties

    public let mine: Bool
    public let changeOutput: Bool
    public let value: Int
    public let address: String?
    public var memo: String?
    public var pluginID: UInt8? = nil
    public var pluginData: IPluginOutputData? = nil

    var pluginDataString: String? = nil

    // MARK: Lifecycle

    public init(mine: Bool, changeOutput: Bool, value: Int, address: String?) {
        self.mine = mine
        self.changeOutput = changeOutput
        self.value = value
        self.address = address
    }
}

// MARK: - BlockInfo

public struct BlockInfo {
    public let headerHash: String
    public let height: Int
    public let timestamp: Int?
}

// MARK: - BalanceInfo

public struct BalanceInfo: Equatable {
    // MARK: Properties

    public let spendable: Int
    public let unspendableTimeLocked: Int
    public let unspendableNotRelayed: Int

    // MARK: Computed Properties

    public var unspendable: Int {
        unspendableNotRelayed + unspendableTimeLocked
    }

    // MARK: Static Functions

    public static func == (lhs: BalanceInfo, rhs: BalanceInfo) -> Bool {
        lhs.spendable == rhs.spendable && lhs.unspendableTimeLocked == rhs.unspendableTimeLocked && lhs
            .unspendableNotRelayed == rhs.unspendableNotRelayed
    }
}
