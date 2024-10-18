//
//  BitsValidator.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/15.
//

import Foundation

public class BitsValidator: IBlockChainedValidator {
    // MARK: Lifecycle

    public init() { }

    // MARK: Functions

    public func validate(block: Block, previousBlock: Block) throws {
        guard block.bits == previousBlock.bits else {
            throw BitcoinCoreErrors.BlockValidation.notEqualBits
        }
    }

    public func isBlockValidatable(block _: Block, previousBlock _: Block) -> Bool {
        true
    }
}
