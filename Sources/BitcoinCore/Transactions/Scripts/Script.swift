//
//  Script.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/22.
//

import Foundation

public class Script {
    // MARK: Properties

    public let scriptData: Data
    public let chunks: [Chunk]

    // MARK: Computed Properties

    public var length: Int { scriptData.count }

    // MARK: Lifecycle

    init(with data: Data, chunks: [Chunk]) {
        scriptData = data
        self.chunks = chunks
    }

    // MARK: Functions

    public func validate(opCodes: Data) throws {
        guard opCodes.count == chunks.count else {
            throw ScriptError.wrongScriptLength
        }
        try chunks.enumerated().forEach { index, chunk in
            if chunk.opCode != opCodes[index] {
                throw ScriptError.wrongSequence
            }
        }
    }
}
