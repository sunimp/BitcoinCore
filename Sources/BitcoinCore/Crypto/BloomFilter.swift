//
//  BloomFilter.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

// MARK: - BloomFilter

public struct BloomFilter {
    // MARK: Properties

    let nHashFuncs: UInt32
    let nTweak: UInt32
    let size: UInt32
    let nFlag: UInt8 = 0
    var filter: [UInt8]
    var elementsCount: Int

    let MAX_FILTER_SIZE: UInt32 = 36000
    let MAX_HASH_FUNCS: UInt32 = 50

    // MARK: Computed Properties

    var data: Data {
        Data(filter)
    }

    // MARK: Lifecycle

    init(elements: [Data]) {
        let nTweak = arc4random_uniform(UInt32.max)
        self.init(elements: elements.count, falsePositiveRate: 0.00005, randomNonce: nTweak)

        for element in elements {
            insert(Data(element))
        }
    }

    init(elements: Int, falsePositiveRate: Double, randomNonce nTweak: UInt32) {
        elementsCount = elements
        size = max(
            1,
            min(UInt32(-1.0 / pow(log(2), 2) * Double(elements) * log(falsePositiveRate)), MAX_FILTER_SIZE * 8) / 8
        )
        filter = [UInt8](repeating: 0, count: Int(size))
        nHashFuncs = max(1, min(UInt32(Double(size * UInt32(8)) / Double(elements) * log(2)), MAX_HASH_FUNCS))
        self.nTweak = nTweak
    }

    // MARK: Functions

    mutating func insert(_ data: Data) {
        for i in 0 ..< nHashFuncs {
            let seed = i &* 0xFBA4C795 &+ nTweak
            let nIndex = Int(MurmurHash.hashValue(data, seed) % (size * 8))
            filter[nIndex >> 3] |= (1 << (7 & nIndex))
        }
    }
}

// MARK: CustomDebugStringConvertible

extension BloomFilter: CustomDebugStringConvertible {
    public var debugDescription: String {
        filter.compactMap { bits(fromByte: $0).map(\.description).joined() }.joined()
    }

    enum Bit: UInt8, CustomStringConvertible {
        case zero
        case one

        // MARK: Computed Properties

        var description: String {
            switch self {
            case .one: "1"
            case .zero: "0"
            }
        }
    }

    func bits(fromByte byte: UInt8) -> [Bit] {
        var byte = byte
        var bits = [Bit](repeating: .zero, count: 8)
        for i in 0 ..< 8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }
            byte >>= 1
        }
        return bits
    }
}
