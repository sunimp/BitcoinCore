//
//  ProofOfWorkValidator.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/15.
//

import Foundation

import BigInt

public class ProofOfWorkValidator: IBlockValidator {
    // MARK: Properties

    private let difficultyEncoder: IDifficultyEncoder

    // MARK: Lifecycle

    public init(difficultyEncoder: IDifficultyEncoder) {
        self.difficultyEncoder = difficultyEncoder
    }

    // MARK: Functions

    public func validate(block: Block, previousBlock _: Block) throws {
        guard difficultyEncoder.compactFrom(hash: block.headerHash) < block.bits else {
            throw BitcoinCoreErrors.BlockValidation.invalidProofOfWork
        }
    }
}
