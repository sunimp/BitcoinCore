//
//  BlockMedianTimeHelper.swift
//  BitcoinCore
//
//  Created by Sun on 2019/10/14.
//

import Foundation

// MARK: - BlockMedianTimeHelper

public class BlockMedianTimeHelper {
    // MARK: Properties

    private let medianTimeSpan = 11
    private let storage: IStorage

    /// This flag must be set ONLY when it's NOT possible to get needed blocks for median time calculation
    private let approximate: Bool

    // MARK: Lifecycle

    public init(storage: IStorage, approximate: Bool = false) {
        self.storage = storage
        self.approximate = approximate
    }
}

// MARK: IBlockMedianTimeHelper

extension BlockMedianTimeHelper: IBlockMedianTimeHelper {
    public var medianTimePast: Int? {
        storage.lastBlock.flatMap {
            if approximate {
                // The median time is 6 blocks earlier which is approximately equal to 1 hour.
                $0.timestamp - 3600
            } else {
                medianTimePast(block: $0)
            }
        }
    }

    public func medianTimePast(block: Block) -> Int? {
        let startIndex = block.height - medianTimeSpan + 1
        let median = storage.timestamps(from: startIndex, to: block.height)

        if block.height >= medianTimeSpan, median.count < medianTimeSpan {
            return nil
        }

        return median[median.count / 2]
    }
}
