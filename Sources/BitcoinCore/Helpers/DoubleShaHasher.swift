//
//  DoubleShaHasher.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/18.
//

import Foundation

import SWCryptoKit

public class DoubleShaHasher: IHasher {
    // MARK: Lifecycle

    public init() { }

    // MARK: Functions

    public func hash(data: Data) -> Data {
        Crypto.doubleSha256(data)
    }
}
