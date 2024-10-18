//
//  Purpose.swift
//  BitcoinCore
//
//  Created by Sun on 2019/9/5.
//

import Foundation

import HDWalletKit

#if compiler(>=6)
extension Purpose: @retroactive CustomStringConvertible { }
#else
extension Purpose: CustomStringConvertible {}
#endif

extension Purpose {
    public var scriptType: ScriptType {
        switch self {
        case .bip44: .p2pkh
        case .bip49: .p2wpkhSh
        case .bip84: .p2wpkh
        case .bip86: .p2tr
        }
    }

    public var description: String {
        switch self {
        case .bip44: "bip44"
        case .bip49: "bip49"
        case .bip84: "bip84"
        case .bip86: "bip86"
        }
    }
}
