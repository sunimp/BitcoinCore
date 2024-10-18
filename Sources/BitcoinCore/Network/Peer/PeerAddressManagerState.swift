//
//  PeerAddressManagerState.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/4.
//

import Foundation

class PeerAddressManagerState {
    // MARK: Properties

    private(set) var usedIps: [String] = []

    // MARK: Functions

    func add(usedIp: String) {
        usedIps.append(usedIp)
    }

    func remove(usedIp: String) {
        usedIps.removeAll(where: { $0 == usedIp })
    }
}
