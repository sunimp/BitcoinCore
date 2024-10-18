//
//  GetDataMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import SWExtensions

/// getdata is used in response to inv, to retrieve the content of a specific object,
/// and is usually sent after receiving an inv packet, after filtering known elements.
/// It can be used to retrieve transactions, but only if they are in the memory pool or
/// relay set - arbitrary access to transactions in the chain is not allowed to avoid
/// having clients start to depend on nodes having full transaction indexes (which modern nodes do not).
public struct GetDataMessage: IMessage {
    // MARK: Properties

    /// Number of inventory entries
    let count: VarInt
    /// Inventory vectors
    let inventoryItems: [InventoryItem]

    // MARK: Computed Properties

    public var description: String {
        "\(count) items(s)"
    }

    // MARK: Lifecycle

    public init(inventoryItems: [InventoryItem]) {
        count = VarInt(inventoryItems.count)
        self.inventoryItems = inventoryItems
    }
}
