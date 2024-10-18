//
//  Output.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/22.
//

import Foundation

import GRDB
import SWExtensions

// MARK: - ScriptType

public enum ScriptType: Int, DatabaseValueConvertible {
    case unknown
    case p2pkh
    case p2pk
    case p2multi
    case p2sh
    case p2wsh
    case p2wpkh
    case p2wpkhSh
    case p2tr
    case nullData

    // MARK: Computed Properties

    var size: Int {
        switch self {
        case .p2pk: 35
        case .p2pkh: 25
        case .p2sh: 23
        case .p2wsh: 34
        case .p2wpkh: 22
        case .p2wpkhSh: 23
        case .p2tr: 34
        default: 0
        }
    }

    var witness: Bool {
        self == .p2wpkh || self == .p2wpkhSh || self == .p2wsh || self == .p2tr
    }
}

// MARK: - Output

public class Output: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression, CaseIterable {
        case value
        case lockingScript
        case index
        case transactionHash
        case publicKeyPath
        case changeOutput
        case scriptType
        case redeemScript
        case keyHash
        case address
        case pluginID
        case pluginData
        case failedToSpend
    }

    // MARK: Overridden Properties

    override open class var databaseTableName: String {
        "outputs"
    }

    // MARK: Properties

    public var value: Int
    public var lockingScript: Data
    public var index: Int
    public var transactionHash: Data
    public var scriptType: ScriptType = .unknown
    public var redeemScript: Data? = nil
    public var lockingScriptPayload: Data? = nil
    public var pluginID: UInt8? = nil
    public var pluginData: String? = nil
    public var signatureScriptFunction: (([Data]) -> Data)? = nil

    var publicKeyPath: String? = nil
    private(set) var changeOutput = false
    var address: String? = nil
    var failedToSpend = false

    // MARK: Lifecycle

    public init(original: Output) {
        value = original.value
        lockingScript = original.lockingScript
        index = original.index
        transactionHash = original.transactionHash
        publicKeyPath = original.publicKeyPath
        changeOutput = original.changeOutput
        scriptType = original.scriptType
        redeemScript = original.redeemScript
        lockingScriptPayload = original.lockingScriptPayload
        address = original.address
        failedToSpend = original.failedToSpend
        pluginID = original.pluginID
        pluginData = original.pluginData
        signatureScriptFunction = original.signatureScriptFunction

        super.init()
    }

    public init(
        withValue value: Int,
        index: Int,
        lockingScript script: Data,
        transactionHash: Data = Data(),
        type: ScriptType = .unknown,
        redeemScript: Data? = nil,
        address: String? = nil,
        lockingScriptPayload: Data? = nil,
        publicKey: PublicKey? = nil
    ) {
        self.value = value
        lockingScript = script
        self.index = index
        self.transactionHash = transactionHash
        scriptType = type
        self.redeemScript = redeemScript
        self.address = address
        self.lockingScriptPayload = lockingScriptPayload

        super.init()

        if let publicKey {
            set(publicKey: publicKey)
        }
    }

    required init(row: Row) throws {
        value = row[Columns.value]
        lockingScript = row[Columns.lockingScript]
        index = row[Columns.index]
        transactionHash = row[Columns.transactionHash]
        publicKeyPath = row[Columns.publicKeyPath]
        changeOutput = row[Columns.changeOutput]
        scriptType = row[Columns.scriptType]
        redeemScript = row[Columns.redeemScript]
        lockingScriptPayload = row[Columns.keyHash]
        address = row[Columns.address]
        pluginID = row[Columns.pluginID]
        pluginData = row[Columns.pluginData]
        failedToSpend = row[Columns.failedToSpend]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override open func encode(to container: inout PersistenceContainer) throws {
        container[Columns.value] = value
        container[Columns.lockingScript] = lockingScript
        container[Columns.index] = index
        container[Columns.transactionHash] = transactionHash
        container[Columns.publicKeyPath] = publicKeyPath
        container[Columns.changeOutput] = changeOutput
        container[Columns.scriptType] = scriptType
        container[Columns.redeemScript] = redeemScript
        container[Columns.keyHash] = lockingScriptPayload
        container[Columns.address] = address
        container[Columns.pluginID] = pluginID
        container[Columns.pluginData] = pluginData
        container[Columns.failedToSpend] = failedToSpend
    }

    // MARK: Functions

    public func set(publicKey: PublicKey) {
        publicKeyPath = publicKey.path
        changeOutput = !publicKey.external
    }
}

extension Output {
    var memo: String? {
        guard scriptType == .nullData, let payload = lockingScriptPayload, !payload.isEmpty, pluginID == nil else {
            return nil
        }

        // read first byte to get data length and parse first message
        let byteStream = ByteStream(payload)
        _ = byteStream.read(UInt8.self) // read op_return
        let length = byteStream.read(VarInt.self).underlyingValue
        if byteStream.availableBytes >= length {
            let data = byteStream.read(Data.self, count: Int(length))
            return String(
                data: data,
                encoding: .utf8
            ) // TODO: make memo manager if need parse not only memo (some instructions)
        }

        return nil
    }
}
