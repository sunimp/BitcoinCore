//
//  BloomFilterLoader.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/3.
//

import Combine
import Foundation

class BloomFilterLoader: IBloomFilterManagerDelegate {
    // MARK: Properties

    private var cancellables = Set<AnyCancellable>()
    private let bloomFilterManager: IBloomFilterManager
    private var peerManager: IPeerManager

    // MARK: Lifecycle

    init(bloomFilterManager: IBloomFilterManager, peerManager: IPeerManager) {
        self.bloomFilterManager = bloomFilterManager
        self.peerManager = peerManager
    }

    // MARK: Functions

    func bloomFilterUpdated(bloomFilter: BloomFilter) {
        for peer in peerManager.connected {
            peer.filterLoad(bloomFilter: bloomFilter)
        }
    }

    func subscribeTo(publisher: AnyPublisher<PeerGroupEvent, Never>) {
        publisher
            .sink { [weak self] event in
                switch event {
                case let .onPeerConnect(peer): self?.onPeerConnect(peer: peer)
                default: ()
                }
            }
            .store(in: &cancellables)
    }

    private func onPeerConnect(peer: IPeer) {
        if let bloomFilter = bloomFilterManager.bloomFilter {
            peer.filterLoad(bloomFilter: bloomFilter)
        }
    }
}
