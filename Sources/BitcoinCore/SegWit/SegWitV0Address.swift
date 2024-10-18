//
//  SegWitV0Address.swift
//  BitcoinCore
//
//  Created by Sun on 2023/3/20.
//

import Foundation

public class SegWitV0Address: Address, Equatable {
    // MARK: Properties

    public let type: AddressType
    public let lockingScriptPayload: Data
    public let stringValue: String

    // MARK: Computed Properties

    public var scriptType: ScriptType {
        switch type {
        case .pubKeyHash: .p2wpkh
        case .scriptHash: .p2wsh
        }
    }

    public var lockingScript: Data {
        OpCode.segWitOutputScript(lockingScriptPayload, versionByte: 0)
    }

    // MARK: Lifecycle

    public init(type: AddressType, payload: Data, bech32: String) {
        self.type = type
        lockingScriptPayload = payload
        stringValue = bech32
    }

    // MARK: Static Functions

    public static func == (lhs: SegWitV0Address, rhs: some Address) -> Bool {
        guard let rhs = rhs as? SegWitV0Address else {
            return false
        }
        return lhs.type == rhs.type && lhs.lockingScriptPayload == rhs.lockingScriptPayload
    }
}
