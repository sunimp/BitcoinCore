//
//  PeerManager.swift
//  BitcoinCore
//
//  Created by Sun on 2018/11/13.
//

import Foundation

class PeerManager: IPeerManager {
    // MARK: Properties

    private var peers: [IPeer] = []

    // MARK: Computed Properties

    var totalPeersCount: Int {
        peers.count
    }

    var connected: [IPeer] {
        peers.filter(\.connected)
    }

    var sorted: [IPeer] {
        connected.sorted(by: { $0.connectionTime < $1.connectionTime })
    }

    var readyPeers: [IPeer] {
        peers.filter { $0.connected && $0.ready }
    }

    // MARK: Functions

    func add(peer: IPeer) {
        peers.append(peer)
    }

    func peerDisconnected(peer: IPeer) {
        if let index = peers.firstIndex(where: { $0.equalTo(peer) }) {
            peers.remove(at: index)
        }
    }

    func disconnectAll() {
        for peer in peers {
            peer.disconnect(error: nil)
        }
    }
}
