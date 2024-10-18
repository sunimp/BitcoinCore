//
//  PeerTaskHandlerChain.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/3.
//

import Foundation

class PeerTaskHandlerChain: IPeerTaskHandler {
    // MARK: Properties

    private var concreteHandlers = [IPeerTaskHandler]()

    // MARK: Functions

    func handleCompletedTask(peer: IPeer, task: PeerTask) -> Bool {
        for handler in concreteHandlers {
            if handler.handleCompletedTask(peer: peer, task: task) {
                return true
            }
        }
        return false
    }

    func add(handler: IPeerTaskHandler) {
        concreteHandlers.append(handler)
    }
}
