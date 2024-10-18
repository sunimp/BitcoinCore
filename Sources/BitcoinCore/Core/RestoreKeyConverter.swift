//
//  RestoreKeyConverter.swift
//  BitcoinCore
//
//  Created by Sun on 2019/9/9.
//

import Foundation

import HDWalletKit

// MARK: - RestoreKeyConverterChain

class RestoreKeyConverterChain: IRestoreKeyConverter {
    // MARK: Properties

    var converters = [IRestoreKeyConverter]()

    // MARK: Functions

    func add(converter: IRestoreKeyConverter) {
        converters.append(converter)
    }

    func keysForApiRestore(publicKey: PublicKey) -> [String] {
        var keys = [String]()
        for converter in converters {
            keys.append(contentsOf: converter.keysForApiRestore(publicKey: publicKey))
        }

        return keys.unique
    }

    func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        var keys = [Data]()
        for converter in converters {
            keys.append(contentsOf: converter.bloomFilterElements(publicKey: publicKey))
        }

        return keys.unique
    }
}

// MARK: - Bip44RestoreKeyConverter

public class Bip44RestoreKeyConverter {
    // MARK: Properties

    let addressConverter: IAddressConverter

    // MARK: Lifecycle

    public init(addressConverter: IAddressConverter) {
        self.addressConverter = addressConverter
    }
}

// MARK: IRestoreKeyConverter

extension Bip44RestoreKeyConverter: IRestoreKeyConverter {
    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        let legacyAddress = try? addressConverter.convert(publicKey: publicKey, type: Purpose.bip44.scriptType)
            .stringValue

        return [legacyAddress].compactMap { $0 }
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        [publicKey.hashP2pkh, publicKey.raw]
    }
}

// MARK: - Bip49RestoreKeyConverter

public class Bip49RestoreKeyConverter {
    // MARK: Properties

    let addressConverter: IAddressConverter

    // MARK: Lifecycle

    public init(addressConverter: IAddressConverter) {
        self.addressConverter = addressConverter
    }
}

// MARK: IRestoreKeyConverter

extension Bip49RestoreKeyConverter: IRestoreKeyConverter {
    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        let wpkhShAddress = try? addressConverter.convert(publicKey: publicKey, type: Purpose.bip49.scriptType)
            .stringValue

        return [wpkhShAddress].compactMap { $0 }
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        [publicKey.hashP2wpkhWrappedInP2sh]
    }
}

// MARK: - Bip84RestoreKeyConverter

public class Bip84RestoreKeyConverter {
    // MARK: Properties

    let addressConverter: IAddressConverter

    // MARK: Lifecycle

    public init(addressConverter: IAddressConverter) {
        self.addressConverter = addressConverter
    }
}

// MARK: IRestoreKeyConverter

extension Bip84RestoreKeyConverter: IRestoreKeyConverter {
    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        let segwitAddress = try? addressConverter.convert(publicKey: publicKey, type: Purpose.bip84.scriptType)
            .stringValue

        return [segwitAddress].compactMap { $0 }
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        [publicKey.hashP2pkh]
    }
}

// MARK: - Bip86RestoreKeyConverter

public class Bip86RestoreKeyConverter {
    // MARK: Properties

    let addressConverter: IAddressConverter

    // MARK: Lifecycle

    public init(addressConverter: IAddressConverter) {
        self.addressConverter = addressConverter
    }
}

// MARK: IRestoreKeyConverter

extension Bip86RestoreKeyConverter: IRestoreKeyConverter {
    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        let taprootAddress = try? addressConverter.convert(publicKey: publicKey, type: Purpose.bip86.scriptType)
            .stringValue

        return [taprootAddress].compactMap { $0 }
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        [publicKey.convertedForP2tr]
    }
}

// MARK: - KeyHashRestoreKeyConverter

public class KeyHashRestoreKeyConverter: IRestoreKeyConverter {
    // MARK: Properties

    let scriptType: ScriptType

    // MARK: Lifecycle

    public init(scriptType: ScriptType) {
        self.scriptType = scriptType
    }

    // MARK: Functions

    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        switch scriptType {
        case .p2tr: [publicKey.convertedForP2tr.sw.hex]
        default: [publicKey.hashP2pkh.sw.hex]
        }
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        switch scriptType {
        case .p2tr: [publicKey.convertedForP2tr]
        default: [publicKey.hashP2pkh]
        }
    }
}

// MARK: - BlockchairCashRestoreKeyConverter

public class BlockchairCashRestoreKeyConverter {
    // MARK: Properties

    let addressConverter: IAddressConverter

    private let prefixCount: Int

    // MARK: Lifecycle

    public init(addressConverter: IAddressConverter, prefix: String) {
        self.addressConverter = addressConverter
        prefixCount = prefix.count + 1
    }
}

// MARK: IRestoreKeyConverter

extension BlockchairCashRestoreKeyConverter: IRestoreKeyConverter {
    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        let legacyAddress = try? addressConverter.convert(publicKey: publicKey, type: .p2pkh).stringValue

        return [legacyAddress].compactMap { $0 }.map { a in
            let index = a.index(a.startIndex, offsetBy: prefixCount)
            return String(a[index...])
        }
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        [publicKey.hashP2pkh, publicKey.raw]
    }
}
