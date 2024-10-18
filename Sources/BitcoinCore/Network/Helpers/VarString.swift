//
//  VarString.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/9.
//

import Foundation

import SWExtensions

// MARK: - VarString

/// Variable length string can be stored using a variable length integer followed by the string itself.
public struct VarString {
    // MARK: Nested Types

    public typealias StringLiteralType = String

    // MARK: Properties

    let length: VarInt
    let value: String

    // MARK: Lifecycle

    init(_ value: String, length: Int) {
        self.value = value
        self.length = VarInt(length)
    }

    // MARK: Functions

    func serialized() -> Data {
        var data = Data()
        data += length.serialized()
        data += value
        return data
    }
}

// MARK: CustomStringConvertible

extension VarString: CustomStringConvertible {
    public var description: String {
        "\(value)"
    }
}
