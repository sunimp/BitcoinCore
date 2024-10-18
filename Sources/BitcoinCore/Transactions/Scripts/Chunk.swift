//
//  Chunk.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/22.
//

import Foundation

public class Chunk: Equatable {
    // MARK: Properties

    let scriptData: Data
    let index: Int
    let payloadRange: Range<Int>?

    // MARK: Computed Properties

    public var opCode: UInt8 { scriptData[index] }
    public var data: Data? {
        guard let payloadRange, scriptData.count >= payloadRange.upperBound else {
            return nil
        }
        return scriptData.subdata(in: payloadRange)
    }

    // MARK: Lifecycle

    public init(scriptData: Data, index: Int, payloadRange: Range<Int>? = nil) {
        self.scriptData = scriptData
        self.index = index
        self.payloadRange = payloadRange
    }

    // MARK: Static Functions

    public static func == (lhs: Chunk, rhs: Chunk) -> Bool {
        lhs.scriptData == rhs.scriptData && lhs.opCode == rhs.opCode && lhs.payloadRange == rhs.payloadRange
    }
}
