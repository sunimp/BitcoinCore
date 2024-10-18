//
//  BitcoinSendInfo.swift
//  BitcoinCore
//
//  Created by Sun on 2023/12/28.
//

import Foundation

public struct BitcoinSendInfo {
    public let unspentOutputs: [UnspentOutput]
    public let fee: Int
    public let changeValue: Int?
    public let changeAddress: Address?
}
