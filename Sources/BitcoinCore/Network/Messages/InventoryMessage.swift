//
//  InventoryMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import SWExtensions

/// Allows a node to advertise its knowledge of one or more objects. It can be received unsolicited, or in reply to
/// getblocks.
struct InventoryMessage: IMessage {
    // MARK: Properties

    /// Number of inventory entries
    let count: VarInt
    /// Inventory vectors
    let inventoryItems: [InventoryItem]

    // MARK: Computed Properties

    var description: String {
        let items = inventoryItems.map { item in
            let objectTypeString =
                if case .unknown = item.objectType {
                    String(item.type)
                } else {
                    "\(item.objectType)"
                }
            return "[\(objectTypeString): \(item.hash.sw.reversedHex)]"
        }.joined(separator: ", ")

        return "\(items)"
    }

    // MARK: Lifecycle

    init(inventoryItems: [InventoryItem]) {
        count = VarInt(inventoryItems.count)
        self.inventoryItems = inventoryItems
    }
}
