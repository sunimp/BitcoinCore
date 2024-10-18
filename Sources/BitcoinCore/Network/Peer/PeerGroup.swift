//
//  PeerGroup.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Combine
import Foundation

import NIO
import SWToolKit

// MARK: - PeerGroupEvent

public enum PeerGroupEvent {
    case onStart
    case onStop
    case onRefresh
    case onPeerCreate(peer: IPeer)
    case onPeerConnect(peer: IPeer)
    case onPeerDisconnect(peer: IPeer, error: Error?)
    case onPeerReady(peer: IPeer)
    case onPeerBusy(peer: IPeer)
}

// MARK: - PeerGroup

class PeerGroup {
    // MARK: Static Properties

    private static let acceptableBlockHeightDifference = 50000
    private static let peerCountToConnect = 100

    // MARK: Properties

    private(set) var started = false

    weak var inventoryItemsHandler: IInventoryItemsHandler?
    weak var peerTaskHandler: IPeerTaskHandler?

    private let factory: IFactory

    private let reachabilityManager: ReachabilityManager
    private var peerAddressManager: IPeerAddressManager
    private var peerManager: IPeerManager

    private let localDownloadedBestBlockHeight: Int32
    private let peerCountToHold: Int // number of peers held
    private var peerCountToConnect: Int? // number of peers to connect to
    private var peerCountConnected = 0 // number of peers connected to

    private let peersQueue: DispatchQueue
    private let inventoryQueue: DispatchQueue
    private var eventLoopGroup: MultiThreadedEventLoopGroup?

    private let logger: Logger?

    private let subject = PassthroughSubject<PeerGroupEvent, Never>()

    // MARK: Computed Properties

    var publisher: AnyPublisher<PeerGroupEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: Lifecycle

    init(
        factory: IFactory,
        reachabilityManager: ReachabilityManager,
        peerAddressManager: IPeerAddressManager,
        peerCount: Int = 10,
        localDownloadedBestBlockHeight: Int32,
        peerManager: IPeerManager,
        peersQueue: DispatchQueue = DispatchQueue(
            label: "com.sunimp.bitcoin-core.peer-group.peers",
            qos: .background
        ),
        inventoryQueue: DispatchQueue = DispatchQueue(
            label: "com.sunimp.bitcoin-core.peer-group.inventory",
            qos: .background
        ),
        logger: Logger? = nil
    ) {
        self.factory = factory

        self.reachabilityManager = reachabilityManager
        self.peerAddressManager = peerAddressManager
        self.localDownloadedBestBlockHeight = localDownloadedBestBlockHeight
        peerCountToHold = peerCount
        self.peerManager = peerManager

        self.peersQueue = peersQueue
        self.inventoryQueue = inventoryQueue
        self.logger = logger

        self.peerAddressManager.delegate = self
    }

    deinit {
        eventLoopGroup?.shutdownGracefully { _ in }
    }

    // MARK: Functions

    private func connectPeersIfRequired() {
        peersQueue.async {
            guard self.started, self.reachabilityManager.isReachable else {
                return
            }

            let _eventLoopGroup: MultiThreadedEventLoopGroup
            if let existing = self.eventLoopGroup {
                _eventLoopGroup = existing
            } else {
                _eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: self.peerCountToHold)
                self.eventLoopGroup = _eventLoopGroup
            }

            var peersToConnect = [IPeer]()

            for _ in self.peerManager.totalPeersCount ..< self.peerCountToHold {
                if let host = self.peerAddressManager.ip {
                    let peer = self.factory.peer(withHost: host, eventLoopGroup: _eventLoopGroup, logger: self.logger)
                    peer.delegate = self
                    peersToConnect.append(peer)
                } else {
                    break
                }
            }

            for peer in peersToConnect {
                self.peerCountConnected += 1
                self.onNext(.onPeerCreate(peer: peer))
                self.peerManager.add(peer: peer)
                peer.connect()
            }
        }
    }

    private func onNext(_ event: PeerGroupEvent) {
        subject.send(event)
    }
}

// MARK: IPeerGroup

extension PeerGroup: IPeerGroup {
    func start() {
        guard !started else {
            return
        }

        started = true
        peerCountConnected = 0

        onNext(.onStart)
        connectPeersIfRequired()
    }

    func stop() {
        started = false

        peerManager.disconnectAll()
        onNext(.onStop)
    }

    func refresh() {
        guard started else {
            return
        }

        onNext(.onRefresh)
    }

    func reconnectPeers() {
        peerManager.disconnectAll()
    }

    func isReady(peer: IPeer) -> Bool {
        peer.ready
    }
}

// MARK: PeerDelegate

extension PeerGroup: PeerDelegate {
    func peerReady(_ peer: IPeer) {
        onNext(.onPeerReady(peer: peer))
    }

    func peerBusy(_ peer: IPeer) {
        onNext(.onPeerBusy(peer: peer))
    }

    func peerDidConnect(_ peer: IPeer) {
        peerAddressManager.markConnected(peer: peer)
        onNext(.onPeerConnect(peer: peer))

        if let peerCountToConnect {
            disconnectSlowestPeer(peerCountToConnect: peerCountToConnect)
        } else {
            setPeerCountToConnect(for: peer)
        }
    }

    private func setPeerCountToConnect(for peer: IPeer) {
        if peer.announcedLastBlockHeight - localDownloadedBestBlockHeight > PeerGroup.acceptableBlockHeightDifference {
            peerCountToConnect = PeerGroup.peerCountToConnect
        } else {
            peerCountToConnect = 0
        }
    }

    private func disconnectSlowestPeer(peerCountToConnect: Int) {
        if peerCountToConnect > peerCountConnected, peerCountToHold > 1, peerAddressManager.hasFreshIps {
            let sortedPeers = peerManager.sorted
            if sortedPeers.count >= peerCountToHold {
                sortedPeers.last?.disconnect(error: nil)
            }
        }
    }

    func peerDidDisconnect(_ peer: IPeer, withError error: Error?) {
        peersQueue.async {
            self.peerManager.peerDisconnected(peer: peer)
        }

        if let error {
            logger?
                .warning(
                    "Peer \(peer.logName)(\(peer.host)) disconnected. Network reachable: \(reachabilityManager.isReachable). Error: \(error)"
                )
        }

        if reachabilityManager.isReachable, error != nil {
            peerAddressManager.markFailed(ip: peer.host)
        } else {
            peerAddressManager.markSuccess(ip: peer.host)
        }

        onNext(.onPeerDisconnect(peer: peer, error: error))
        connectPeersIfRequired()
    }

    func peer(_ peer: IPeer, didCompleteTask task: PeerTask) {
        _ = peerTaskHandler?.handleCompletedTask(peer: peer, task: task)
    }

    func peer(_ peer: IPeer, didReceiveMessage message: IMessage) {
        switch message {
        case let addressMessage as AddressMessage:
            let addresses = addressMessage.addressList
                .filter { $0.supportsBloomFilter() }
                .map(\.address)

            peerAddressManager.add(ips: addresses)

        case let inventoryMessage as InventoryMessage:
            inventoryQueue.async {
                self.inventoryItemsHandler?.handleInventoryItems(
                    peer: peer,
                    inventoryItems: inventoryMessage.inventoryItems
                )
            }

        default: ()
        }
    }
}

// MARK: IPeerAddressManagerDelegate

extension PeerGroup: IPeerAddressManagerDelegate {
    func newIpsAdded() {
        connectPeersIfRequired()
    }
}
