//
//  NetworkMessageSerializer.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/19.
//

import Foundation

import SWCryptoKit
import SWExtensions

// MARK: - NetworkMessageSerializer

class NetworkMessageSerializer: INetworkMessageSerializer {
    // MARK: Properties

    let magic: UInt32
    var messageSerializers = [IMessageSerializer]()

    // MARK: Lifecycle

    init(magic: UInt32) {
        self.magic = magic
    }

    // MARK: Functions

    func add(serializer: IMessageSerializer) {
        messageSerializers.append(serializer)
    }

    func serialize(message: IMessage) throws -> Data {
        var resolvedSerializer: IMessageSerializer? = nil
        var resolvedMessageData: Data? = nil

        for serializer in messageSerializers {
            if let messageData = serializer.serialize(message: message) {
                resolvedSerializer = serializer
                resolvedMessageData = messageData
                break
            }
        }

        guard let serializer = resolvedSerializer, let messageData = resolvedMessageData else {
            throw BitcoinCoreErrors.MessageSerialization.noMessageSerializer
        }
        let checksum = Data(Crypto.doubleSha256(messageData).prefix(4))
        let length = UInt32(messageData.count)

        var data = Data()
        data += magic.bigEndian
        var bytes = [UInt8](serializer.id.data(using: .ascii)!)
        bytes.append(contentsOf: [UInt8](repeating: 0, count: 12 - bytes.count))
        data += bytes
        data += length.littleEndian
        data += checksum
        data += messageData

        return data
    }
}

// MARK: - GetDataMessageSerializer

class GetDataMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "getdata" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? GetDataMessage else {
            return nil
        }

        var data = Data()

        data += message.count.serialized()
        data += message.inventoryItems.flatMap {
            $0.serialized()
        }

        return data
    }
}

// MARK: - GetBlocksMessageSerializer

class GetBlocksMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "getblocks" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? GetBlocksMessage else {
            return nil
        }

        var data = Data()
        data += message.version
        data += message.hashCount.serialized()
        for hash in message.blockLocatorHashes {
            data += hash
        }
        data += message.hashStop
        return data
    }
}

// MARK: - InventoryMessageSerializer

class InventoryMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "inv" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? InventoryMessage else {
            return nil
        }

        var data = Data()
        data += message.count.serialized()
        data += message.inventoryItems.flatMap {
            $0.serialized()
        }
        return data
    }
}

// MARK: - PingMessageSerializer

class PingMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "ping" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? PingMessage else {
            return nil
        }

        var data = Data()
        data += message.nonce
        return data
    }
}

// MARK: - PongMessageSerializer

class PongMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "pong" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? PongMessage else {
            return nil
        }

        var data = Data()
        data += message.nonce
        return data
    }
}

// MARK: - VersionMessageSerializer

class VersionMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "version" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? VersionMessage else {
            return nil
        }

        var data = Data()
        data += message.version.littleEndian
        data += message.services.littleEndian
        data += message.timestamp.littleEndian
        data += message.yourAddress.serialized()
        data += message.myAddress?.serialized() ?? Data(count: 26)
        data += message.nonce?.littleEndian ?? UInt64(0)
        data += message.userAgent?.serialized() ?? Data([UInt8(0x00)])
        data += message.startHeight?.littleEndian ?? Int32(0)
        data += message.relay ?? false
        return data
    }
}

// MARK: - VerackMessageSerializer

class VerackMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "verack" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard message is VerackMessage else {
            return nil
        }

        return Data()
    }
}

// MARK: - MempoolMessageSerializer

class MempoolMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "mempool" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard message is MemPoolMessage else {
            return nil
        }

        return Data()
    }
}

// MARK: - TransactionMessageSerializer

class TransactionMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "tx" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? TransactionMessage else {
            return nil
        }

        return TransactionSerializer.serialize(transaction: message.transaction)
    }
}

// MARK: - FilterLoadMessageSerializer

class FilterLoadMessageSerializer: IMessageSerializer {
    // MARK: Computed Properties

    var id: String { "filterload" }

    // MARK: Functions

    func serialize(message: IMessage) -> Data? {
        guard let message = message as? FilterLoadMessage else {
            return nil
        }

        let bloomFilter = message.bloomFilter

        var data = Data()
        data += VarInt(bloomFilter.filter.count).serialized()
        data += bloomFilter.filter
        data += bloomFilter.nHashFuncs
        data += bloomFilter.nTweak
        data += bloomFilter.nFlag
        return data
    }
}
