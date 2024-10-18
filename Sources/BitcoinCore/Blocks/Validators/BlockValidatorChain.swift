//
//  BlockValidatorChain.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/15.
//

import Foundation

public class BlockValidatorChain: IBlockValidator {
    // MARK: Properties

    private var validators = [IBlockChainedValidator]()

    // MARK: Lifecycle

    public init() { }

    // MARK: Functions

    public func validate(block: Block, previousBlock: Block) throws {
        if
            let index = validators
                .firstIndex(where: { $0.isBlockValidatable(block: block, previousBlock: previousBlock) }) {
            try validators[index].validate(block: block, previousBlock: previousBlock)
        }
    }

    public func add(blockValidator: IBlockChainedValidator) {
        validators.append(blockValidator)
    }
}
