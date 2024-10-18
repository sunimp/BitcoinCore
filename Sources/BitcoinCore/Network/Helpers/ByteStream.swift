//
//  ByteStream.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation
import SWExtensions

public class ByteStream {
    // MARK: Properties

    public let data: Data

    private var offset = 0

    // MARK: Computed Properties

    public var availableBytes: Int {
        data.count - offset
    }

    public var last: UInt8? {
        data[offset]
    }

    // MARK: Lifecycle

    public init(_ data: Data) {
        self.data = data
    }

    // MARK: Functions

    public func read<T>(_ type: T.Type) -> T {
        let size = MemoryLayout<T>.size
        let value = data[offset ..< (offset + size)].sw.to(type: type)
        offset += size
        return value
    }

    public func read(_: VarInt.Type) -> VarInt {
        guard data.count > offset else {
            return VarInt(0)
        }

        let len = data[offset ..< (offset + 1)].sw.to(type: UInt8.self)
        let length: UInt64
        switch len {
        case 0 ... 252:
            length = UInt64(len)
            offset += 1

        case 0xFD:
            offset += 1
            length = UInt64(data[offset ..< (offset + 2)].sw.to(type: UInt16.self))
            offset += 2

        case 0xFE:
            offset += 1
            length = UInt64(data[offset ..< (offset + 4)].sw.to(type: UInt32.self))
            offset += 4

        case 0xFF:
            offset += 1
            length = UInt64(data[offset ..< (offset + 8)].sw.to(type: UInt64.self))
            offset += 8

        default:
            offset += 1
            length = UInt64(data[offset ..< (offset + 8)].sw.to(type: UInt64.self))
            offset += 8
        }
        return VarInt(length)
    }

    public func read(_: VarString.Type) -> VarString {
        let length = read(VarInt.self).underlyingValue
        let size = Int(length)
        let value = data[offset ..< (offset + size)].sw.to(type: String.self)
        offset += size
        return VarString(value, length: size)
    }

    public func read(_: Data.Type, count: Int) -> Data {
        let value = data[offset ..< (offset + count)]
        offset += count
        return Data(value)
    }
}
