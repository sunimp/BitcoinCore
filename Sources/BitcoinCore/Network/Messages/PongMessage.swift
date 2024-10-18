//
//  PongMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

/// The pong message is sent in response to a ping message.
/// In modern protocol versions, a pong response is generated using a nonce included in the ping.
struct PongMessage: IMessage {
    // MARK: Properties

    /// nonce from ping
    let nonce: UInt64

    // MARK: Computed Properties

    var description: String {
        "\(nonce)"
    }
}
