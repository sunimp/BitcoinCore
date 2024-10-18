//
//  AddressMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

/// Provide information on known nodes of the network. Non-advertised nodes should be forgotten after typically 3 hours
struct AddressMessage: IMessage {
    // MARK: Properties

    /// Address of other nodes on the network. version < 209 will only read the first one.
    /// The uint32_t is a timestamp (see note below).
    let addressList: [NetworkAddress]

    // MARK: Computed Properties

    var description: String {
        "\(addressList.count) address(es)"
    }

    // MARK: Lifecycle

    init(addresses: [NetworkAddress]) {
        addressList = addresses
    }
}
