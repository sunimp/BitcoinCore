//
//  PingMessage.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

/// The ping message is sent primarily to confirm that the TCP/IP connection is still valid.
/// An error in transmission is presumed to be a closed connection and the address is removed as a current peer.
struct PingMessage: IMessage {
    // MARK: Properties

    /// random nonce
    let nonce: UInt64

    // MARK: Computed Properties

    var description: String {
        "\(nonce)"
    }
}
