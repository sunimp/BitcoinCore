//
//  DataObjects.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/22.
//

import Foundation

import SWCryptoKit

// MARK: - BlockHeader

public struct BlockHeader {
    // MARK: Properties

    public let version: Int
    public let headerHash: Data
    public let previousBlockHeaderHash: Data
    public let merkleRoot: Data
    public let timestamp: Int
    public let bits: Int
    public let nonce: Int

    // MARK: Lifecycle

    public init(
        version: Int,
        headerHash: Data,
        previousBlockHeaderHash: Data,
        merkleRoot: Data,
        timestamp: Int,
        bits: Int,
        nonce: Int
    ) {
        self.version = version
        self.headerHash = headerHash
        self.previousBlockHeaderHash = previousBlockHeaderHash
        self.merkleRoot = merkleRoot
        self.timestamp = timestamp
        self.bits = bits
        self.nonce = nonce
    }
}

// MARK: - FullTransaction

open class FullTransaction {
    // MARK: Properties

    public let header: Transaction
    public let inputs: [Input]
    public let outputs: [Output]
    public let metaData = TransactionMetadata()

    // MARK: Lifecycle

    public init(header: Transaction, inputs: [Input], outputs: [Output], forceHashUpdate: Bool = true) {
        self.header = header
        self.inputs = inputs
        self.outputs = outputs

        if forceHashUpdate {
            let hash = Crypto.doubleSha256(TransactionSerializer.serialize(transaction: self, withoutWitness: true))
            set(hash: hash)
        }
    }

    // MARK: Functions

    public func set(hash: Data) {
        header.dataHash = hash
        metaData.transactionHash = hash

        for input in inputs {
            input.transactionHash = header.dataHash
        }
        for output in outputs {
            output.transactionHash = header.dataHash
        }
    }
}

// MARK: - InputToSign

public struct InputToSign {
    let input: Input
    let previousOutput: Output
    let previousOutputPublicKey: PublicKey
}

// MARK: - OutputWithPublicKey

public struct OutputWithPublicKey {
    let output: Output
    let publicKey: PublicKey
    let spendingInput: Input?
    let spendingBlockHeight: Int?
}

// MARK: - InputWithPreviousOutput

public struct InputWithPreviousOutput {
    let input: Input
    let previousOutput: Output?
}

// MARK: - TransactionWithBlock

public struct TransactionWithBlock {
    public let transaction: Transaction

    let blockHeight: Int?
}

// MARK: - UnspentOutput

public struct UnspentOutput {
    // MARK: Properties

    public let output: Output
    public let publicKey: PublicKey
    public let transaction: Transaction
    public let blockHeight: Int?

    // MARK: Computed Properties

    public var info: UnspentOutputInfo {
        .init(
            outputIndex: output.index,
            transactionHash: output.transactionHash,
            timestamp: TimeInterval(transaction.timestamp),
            address: output.address,
            value: output.value
        )
    }

    // MARK: Lifecycle

    public init(output: Output, publicKey: PublicKey, transaction: Transaction, blockHeight: Int? = nil) {
        self.output = output
        self.publicKey = publicKey
        self.transaction = transaction
        self.blockHeight = blockHeight
    }
}

// MARK: - UnspentOutputInfo

public struct UnspentOutputInfo: Hashable, Equatable {
    // MARK: Properties

    public var outputIndex: Int
    public var transactionHash: Data
    public let timestamp: TimeInterval
    public let address: String?
    public let value: Int

    // MARK: Static Functions

    public static func == (lhs: UnspentOutputInfo, rhs: UnspentOutputInfo) -> Bool {
        lhs.outputIndex == rhs.outputIndex &&
            lhs.transactionHash == rhs.transactionHash
    }

    // MARK: Functions

    public func hash(into hasher: inout Hasher) {
        hasher.combine(outputIndex)
        hasher.combine(transactionHash)
    }
}

extension [UnspentOutputInfo] {
    public func outputs(from outputs: [UnspentOutput]) -> [UnspentOutput] {
        let selectedKeys = map { ($0.outputIndex, $0.transactionHash) }
        return outputs.filter { output in
            selectedKeys.contains { i, hash in
                i == output.output.index && hash == output.output.transactionHash
            }
        }
    }
}

// MARK: - FullTransactionForInfo

public struct FullTransactionForInfo {
    // MARK: Properties

    public let transactionWithBlock: TransactionWithBlock

    let inputsWithPreviousOutputs: [InputWithPreviousOutput]
    let outputs: [Output]
    let metaData: TransactionMetadata

    // MARK: Computed Properties

    var rawTransaction: String {
        TransactionSerializer.serialize(transaction: fullTransaction).sw.hex
    }

    var fullTransaction: FullTransaction {
        .init(
            header: transactionWithBlock.transaction,
            inputs: inputsWithPreviousOutputs.map(\.input),
            outputs: outputs
        )
    }
}

// MARK: - PublicKeyWithUsedState

public struct PublicKeyWithUsedState {
    let publicKey: PublicKey
    let used: Bool
}
