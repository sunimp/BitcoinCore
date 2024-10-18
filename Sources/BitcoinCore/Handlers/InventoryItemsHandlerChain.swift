//
//  InventoryItemsHandlerChain.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/3.
//

import Foundation

class InventoryItemsHandlerChain: IInventoryItemsHandler {
    // MARK: Properties

    private var concreteHandlers = [IInventoryItemsHandler]()

    // MARK: Functions

    func handleInventoryItems(peer: IPeer, inventoryItems: [InventoryItem]) {
        for handler in concreteHandlers {
            handler.handleInventoryItems(peer: peer, inventoryItems: inventoryItems)
        }
    }

    func add(handler: IInventoryItemsHandler) {
        concreteHandlers.append(handler)
    }
}
