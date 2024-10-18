//
//  LegacyDifficultyAdjustmentValidator.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/15.
//

import Foundation

import BigInt

public class LegacyDifficultyAdjustmentValidator: IBlockChainedValidator {
    // MARK: Properties

    let difficultyEncoder: IDifficultyEncoder
    let blockValidatorHelper: IBlockValidatorHelper

    private let heightInterval: Int
    private let targetTimespan: Int
    private let maxTargetBits: Int

    // MARK: Lifecycle

    public init(
        encoder: IDifficultyEncoder,
        blockValidatorHelper: IBlockValidatorHelper,
        heightInterval: Int,
        targetTimespan: Int,
        maxTargetBits: Int
    ) {
        difficultyEncoder = encoder
        self.blockValidatorHelper = blockValidatorHelper

        self.heightInterval = heightInterval
        self.targetTimespan = targetTimespan
        self.maxTargetBits = maxTargetBits
    }

    // MARK: Functions

    public func validate(block: Block, previousBlock: Block) throws {
        guard let firstBlock = blockValidatorHelper.previous(for: previousBlock, count: heightInterval - 1) else {
            throw BitcoinCoreErrors.BlockValidation.noPreviousBlock
        }
        var timespan = previousBlock.timestamp - firstBlock.timestamp
        if timespan < targetTimespan / 4 {
            timespan = targetTimespan / 4
        } else if timespan > targetTimespan * 4 {
            timespan = targetTimespan * 4
        }

        var bigIntDifficulty = difficultyEncoder.decodeCompact(bits: previousBlock.bits)
        bigIntDifficulty *= BigInt(timespan)
        bigIntDifficulty /= BigInt(targetTimespan)
        var newDifficulty = difficultyEncoder.encodeCompact(from: bigIntDifficulty)

        // Difficulty hit proof of work limit: newTarget
        if newDifficulty > maxTargetBits {
            newDifficulty = maxTargetBits
        }

        guard newDifficulty == block.bits else {
            throw BitcoinCoreErrors.BlockValidation.notDifficultyTransitionEqualBits
        }
    }

    public func isBlockValidatable(block: Block, previousBlock _: Block) -> Bool {
        block.height % heightInterval == 0
    }
}
