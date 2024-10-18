//
//  BlockHashScanHelper.swift
//  BitcoinCore
//
//  Created by Sun on 2019/2/26.
//

import Foundation

// MARK: - IBlockHashScanHelper

protocol IBlockHashScanHelper {
    func lastUsedIndex(addresses: [[String]], items: [ApiAddressItem]) -> Int
}

// MARK: - BlockHashScanHelper

class BlockHashScanHelper: IBlockHashScanHelper {
    func lastUsedIndex(addresses: [[String]], items: [ApiAddressItem]) -> Int {
        guard !addresses.isEmpty else {
            return -1
        }

        let searchAddressStrings = items.map(\.address)
        let searchScriptStrings = items.map(\.script)

        let lastIndex = addresses.count - 1
        for i in 0 ... lastIndex {
            for address in addresses[lastIndex - i] {
                if
                    searchAddressStrings.contains(address) ||
                    searchScriptStrings.firstIndex(where: { script in script.contains(address) }) != nil {
                    return lastIndex - i
                }
            }
        }
        return -1
    }
}

// MARK: - WatchAddressBlockHashScanHelper

class WatchAddressBlockHashScanHelper: IBlockHashScanHelper {
    func lastUsedIndex(addresses _: [[String]], items _: [ApiAddressItem]) -> Int { -1 }
}
