//
//  BlockValidatorHelper.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/15.
//

import Foundation

open class BlockValidatorHelper: IBlockValidatorHelper {
    // MARK: Properties

    let storage: IStorage

    // MARK: Lifecycle

    public init(storage: IStorage) {
        self.storage = storage
    }

    // MARK: Functions

    public func previous(for block: Block, count: Int) -> Block? {
        let previousHeight = block.height - count
        guard let previousBlock = storage.blockByHeightStalePrioritized(height: previousHeight) else {
            return nil
        }
        return previousBlock
    }

    public func previousWindow(for block: Block, count: Int) -> [Block]? {
        let firstIndex = block.height - count
        let blocks = storage.blocks(from: firstIndex, to: block.height - 1, ascending: true)
        guard blocks.count == count else {
            return nil
        }
        return blocks
    }
}
