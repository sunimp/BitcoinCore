//
//  BlockSyncerState.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/8.
//

import Foundation

class BlockSyncerState {
    // MARK: Properties

    private(set) var iterationHasPartialBlocks = false

    // MARK: Functions

    func iteration(hasPartialBlocks state: Bool) {
        iterationHasPartialBlocks = state
    }
}
