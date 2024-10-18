//
//  ConnectionTimeoutManager.swift
//  BitcoinCore
//
//  Created by Sun on 2018/11/29.
//

import Foundation

import SWToolKit

class ConnectionTimeoutManager: IConnectionTimeoutManager {
    // MARK: Nested Types

    enum TimeoutError: Error {
        case pingTimedOut
    }

    // MARK: Properties

    private var messageLastReceivedTime: Double? = nil
    private var lastPingTime: Double? = nil
    private let maxIdleTime = 60.0
    private let pingTimeout = 5.0

    private let logger: Logger?
    private let dateGenerator: () -> Date

    // MARK: Lifecycle

    init(dateGenerator: @escaping () -> Date = Date.init, logger: Logger? = nil) {
        self.logger = logger
        self.dateGenerator = dateGenerator
    }

    // MARK: Functions

    func reset() {
        messageLastReceivedTime = dateGenerator().timeIntervalSince1970
        lastPingTime = nil
    }

    func timePeriodPassed(peer: IPeer) {
        if let lastPingTime {
            if dateGenerator().timeIntervalSince1970 - lastPingTime > pingTimeout {
                logger?.error("Timed out. Closing connection", context: [peer.logName])
                peer.disconnect(error: TimeoutError.pingTimedOut)
            }

            return
        }

        if let messageLastReceivedTime {
            if dateGenerator().timeIntervalSince1970 - messageLastReceivedTime > maxIdleTime {
                logger?.debug("Timed out. Closing connection", context: [peer.logName])
                peer.sendPing(nonce: UInt64.random(in: 0 ..< UINT64_MAX))
                lastPingTime = dateGenerator().timeIntervalSince1970
            }
        }
    }
}
