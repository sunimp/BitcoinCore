//
//  SigHashType.swift
//  BitcoinCore
//
//  Created by Sun on 2018/10/24.
//

import Foundation

public enum SigHashType {
    case bitcoinAll
    case bitcoinTaprootAll
    case bitcoinCashAll

    // MARK: Computed Properties

    var value: UInt8 {
        switch self {
        case .bitcoinAll: 0x01
        case .bitcoinTaprootAll: 0x00
        case .bitcoinCashAll: 0x41
        }
    }

    var forked: Bool {
        switch self {
        case .bitcoinAll: false
        case .bitcoinTaprootAll: false
        case .bitcoinCashAll: true
        }
    }
}
