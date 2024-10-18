//
//  Bech32.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/11.
//

//  Base32 address format for native v0-16 witness outputs implementation
//  https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki
//  Inspired by Pieter Wuille C++ implementation

import Foundation

// MARK: - Bech32

/// Bech32 checksum implementation
public class Bech32 {
    // MARK: Properties

    private let gen: [UInt32] = [0x3B6A57B2, 0x26508E6D, 0x1EA119FA, 0x3D4233DD, 0x2A1462B3]
    /// Bech32 checksum delimiter
    private let checksumMarker = "1"
    /// Bech32 character set for encoding
    private let encCharset: Data = "qpzry9x8gf2tvdw0s3jn54khce6mua7l".data(using: .utf8)!
    /// Bech32 character set for decoding
    private let decCharset: [Int8] = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        15, -1, 10, 17, 21, 20, 26, 30, 7, 5, -1, -1, -1, -1, -1, -1,
        -1, 29, -1, 24, 13, 25, 9, 8, 23, -1, 18, 22, 31, 27, 19, -1,
        1, 0, 3, 16, 11, 28, 12, 14, 6, 4, 2, -1, -1, -1, -1, -1,
        -1, 29, -1, 24, 13, 25, 9, 8, 23, -1, 18, 22, 31, 27, 19, -1,
        1, 0, 3, 16, 11, 28, 12, 14, 6, 4, 2, -1, -1, -1, -1, -1,
    ]

    // MARK: Lifecycle

    public init() { }

    // MARK: Functions

    /// Encode Bech32 string
    public func encode(_ hrp: String, values: Data, encoding: Encoding) -> String {
        let checksum = createChecksum(hrp: hrp, values: values, encoding: encoding)
        var combined = values
        combined.append(checksum)
        guard let hrpBytes = hrp.data(using: .utf8) else {
            return ""
        }
        var ret = hrpBytes
        ret.append("1".data(using: .utf8)!)
        for i in combined {
            ret.append(encCharset[Int(i)])
        }
        return String(data: ret, encoding: .utf8) ?? ""
    }

    /// Decode Bech32 string
    public func decode(_ str: String) throws -> (hrp: String, checksum: Data, encoding: Encoding) {
        guard let strBytes = str.data(using: .utf8) else {
            throw DecodingError.nonUTF8String
        }
        guard strBytes.count <= 90 else {
            throw DecodingError.stringLengthExceeded
        }
        var lower = false
        var upper = false
        for c in strBytes {
            // printable range
            if c < 33 || c > 126 {
                throw DecodingError.nonPrintableCharacter
            }
            // 'a' to 'z'
            if c >= 97, c <= 122 {
                lower = true
            }
            // 'A' to 'Z'
            if c >= 65, c <= 90 {
                upper = true
            }
        }
        if lower, upper {
            throw DecodingError.invalidCase
        }
        guard let pos = str.range(of: checksumMarker, options: .backwards)?.lowerBound else {
            throw DecodingError.noChecksumMarker
        }
        let intPos: Int = str.distance(from: str.startIndex, to: pos)
        guard intPos >= 1 else {
            throw DecodingError.incorrectHrpSize
        }
        guard intPos + 7 <= str.count else {
            throw DecodingError.incorrectChecksumSize
        }
        let vSize: Int = str.count - 1 - intPos
        var values = Data(repeating: 0x00, count: vSize)
        for i in 0 ..< vSize {
            let c = strBytes[i + intPos + 1]
            let decInt = decCharset[Int(c)]
            if decInt == -1 {
                throw DecodingError.invalidCharacter
            }
            values[i] = UInt8(decInt)
        }
        let hrp = String(str[..<pos]).lowercased()
        guard
            let (check, encoding) = extractChecksumWithEncoding(hrp: hrp, checksum: values),
            check == encoding.checksumXorConstant
        else {
            throw DecodingError.checksumMismatch
        }
        return (hrp, Data(values[..<(vSize - 6)]), encoding)
    }

    /// Find the polynomial with value coefficients mod the generator as 30-bit.
    private func polymod(_ values: Data) -> UInt32 {
        var chk: UInt32 = 1
        for v in values {
            let top = (chk >> 25)
            chk = (chk & 0x1FFFFFF) << 5 ^ UInt32(v)
            for i: UInt8 in 0 ..< 5 {
                chk ^= ((top >> i) & 1) == 0 ? 0 : gen[Int(i)]
            }
        }
        return chk
    }

    /// Expand a HRP for use in checksum computation.
    private func expandHrp(_ hrp: String) -> Data {
        guard let hrpBytes = hrp.data(using: .utf8) else {
            return Data()
        }
        var result = Data(repeating: 0x00, count: hrpBytes.count * 2 + 1)
        for (i, c) in hrpBytes.enumerated() {
            result[i] = c >> 5
            result[i + hrpBytes.count + 1] = c & 0x1F
        }
        result[hrp.count] = 0
        return result
    }

    private func extractChecksumWithEncoding(hrp: String, checksum: Data) -> (check: UInt32, encoding: Encoding)? {
        var data = expandHrp(hrp)
        data.append(checksum)
        let check = polymod(data)
        return Encoding.fromCheck(check).flatMap { (check, $0) }
    }

    /// Create checksum
    private func createChecksum(hrp: String, values: Data, encoding: Encoding) -> Data {
        var enc = expandHrp(hrp)
        enc.append(values)
        enc.append(Data(repeating: 0x00, count: 6))
        let mod: UInt32 = polymod(enc) ^ encoding.checksumXorConstant
        var ret = Data(repeating: 0x00, count: 6)
        for i in 0 ..< 6 {
            ret[i] = UInt8((mod >> (5 * (5 - i))) & 31)
        }
        return ret
    }
}

extension Bech32 {
    public enum DecodingError: LocalizedError {
        case nonUTF8String
        case nonPrintableCharacter
        case invalidCase
        case noChecksumMarker
        case incorrectHrpSize
        case incorrectChecksumSize
        case stringLengthExceeded

        case invalidCharacter
        case checksumMismatch

        // MARK: Computed Properties

        public var errorDescription: String? {
            switch self {
            case .checksumMismatch:
                "Checksum doesn't match"
            case .incorrectChecksumSize:
                "Checksum size too low"
            case .incorrectHrpSize:
                "Human-readable-part is too small or empty"
            case .invalidCase:
                "String contains mixed case characters"
            case .invalidCharacter:
                "Invalid character met on decoding"
            case .noChecksumMarker:
                "Checksum delimiter not found"
            case .nonPrintableCharacter:
                "Non printable character in input string"
            case .nonUTF8String:
                "String cannot be decoded by utf8 decoder"
            case .stringLengthExceeded:
                "Input string is too long"
            }
        }
    }

    public enum Encoding {
        case bech32
        case bech32m

        // MARK: Computed Properties

        var checksumXorConstant: UInt32 {
            switch self {
            case .bech32: 1
            case .bech32m: 0x2BC830A3
            }
        }

        // MARK: Static Functions

        static func fromCheck(_ check: UInt32) -> Encoding? {
            switch check {
            case Encoding.bech32.checksumXorConstant: .bech32
            case Encoding.bech32m.checksumXorConstant: .bech32m
            default: nil
            }
        }
    }
}
