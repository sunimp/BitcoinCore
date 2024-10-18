//
//  TransactionSendTimer.swift
//  BitcoinCore
//
//  Created by Sun on 2019/11/19.
//

import Foundation

// MARK: - TransactionSendTimer

class TransactionSendTimer {
    // MARK: Properties

    let interval: TimeInterval

    weak var delegate: ITransactionSendTimerDelegate?
    var runLoop: RunLoop?
    var timer: Timer?

    // MARK: Lifecycle

    init(interval: TimeInterval) {
        self.interval = interval
    }
}

// MARK: ITransactionSendTimer

extension TransactionSendTimer: ITransactionSendTimer {
    func startIfNotRunning() {
        guard runLoop == nil else {
            return
        }

        DispatchQueue.global(qos: .background).async {
            self.runLoop = .current

            let timer = Timer(
                timeInterval: self.interval,
                repeats: true,
                block: { [weak self] _ in self?.delegate?.timePassed() }
            )
            self.timer = timer

            RunLoop.current.add(timer, forMode: .common)
            RunLoop.current.run()
        }
    }

    func stop() {
        if let runLoop {
            timer?.invalidate()
            timer?.invalidate()

            CFRunLoopStop(runLoop.getCFRunLoop())
            timer = nil
            self.runLoop = nil
        }
    }
}
