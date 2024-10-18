//
//  TaprootAddress.swift
//  BitcoinCore
//
//  Created by Sun on 2023/3/10.
//

import Foundation

public class TaprootAddress: Address, Equatable {
    // MARK: Properties

    public let lockingScriptPayload: Data
    public let stringValue: String
    public let version: UInt8
    public var scriptType = ScriptType.p2tr

    // MARK: Computed Properties

    public var lockingScript: Data {
        OpCode.segWitOutputScript(lockingScriptPayload, versionByte: Int(version))
    }

    // MARK: Lifecycle

    public init(payload: Data, bech32m: String, version: UInt8) {
        lockingScriptPayload = payload
        stringValue = bech32m
        self.version = version
    }

    // MARK: Static Functions

    public static func == (lhs: TaprootAddress, rhs: some Address) -> Bool {
        guard let rhs = rhs as? TaprootAddress else {
            return false
        }
        return lhs.lockingScriptPayload == rhs.lockingScriptPayload && lhs.version == rhs.version
    }
}
