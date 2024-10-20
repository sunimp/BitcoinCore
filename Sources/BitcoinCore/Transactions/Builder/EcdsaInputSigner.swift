//
//  EcdsaInputSigner.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/9.
//

import Foundation

import HDWalletKit
import SWCryptoKit
import SWExtensions

// MARK: - EcdsaInputSigner

class EcdsaInputSigner {
    // MARK: Nested Types

    enum SignError: Error {
        case noPreviousOutput
        case noPreviousOutputAddress
        case noPrivateKey
    }

    // MARK: Properties

    let hdWallet: IPrivateHDWallet
    let network: INetwork

    // MARK: Lifecycle

    init(hdWallet: IPrivateHDWallet, network: INetwork) {
        self.hdWallet = hdWallet
        self.network = network
    }
}

// MARK: IInputSigner

extension EcdsaInputSigner: IInputSigner {
    func sigScriptData(
        transaction: Transaction,
        inputsToSign: [InputToSign],
        outputs: [Output],
        index: Int
    ) throws
        -> [Data] {
        let input = inputsToSign[index]
        let previousOutput = input.previousOutput
        let pubKey = input.previousOutputPublicKey
        let publicKey = pubKey.raw

        guard
            let privateKeyData = try? hdWallet.privateKeyData(
                account: pubKey.account,
                index: pubKey.index,
                external: pubKey.external
            )
        else {
            throw SignError.noPrivateKey
        }
        let witness = previousOutput.scriptType == .p2wpkh || previousOutput.scriptType == .p2wpkhSh

        var serializedTransaction = try TransactionSerializer.serializedForSignature(
            transaction: transaction,
            inputsToSign: inputsToSign,
            outputs: outputs,
            inputIndex: index,
            forked: witness || network.sigHash.forked
        )
        serializedTransaction += UInt32(network.sigHash.value)
        let signatureHash = Crypto.doubleSha256(serializedTransaction)
        let signature = try Crypto.sign(data: signatureHash, privateKey: privateKeyData) + Data([network.sigHash.value])

        switch previousOutput.scriptType {
        case .p2pk: return [signature]
        default: return [signature, publicKey]
        }
    }
}
