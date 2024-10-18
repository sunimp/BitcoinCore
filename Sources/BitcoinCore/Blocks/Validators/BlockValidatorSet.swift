//
//  BlockValidatorSet.swift
//  BitcoinCore
//
//  Created by Sun on 2020/3/3.
//

import Foundation

public class BlockValidatorSet: IBlockValidator {
    // MARK: Properties

    private var validators = [IBlockValidator]()

    // MARK: Lifecycle

    public init() { }

    // MARK: Functions

    public func validate(block: Block, previousBlock: Block) throws {
        for validator in validators {
            try validator.validate(block: block, previousBlock: previousBlock)
        }
    }

    public func add(blockValidator: IBlockValidator) {
        validators.append(blockValidator)
    }
}
