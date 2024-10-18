//
//  NetworkMessageParser.swift
//  BitcoinCore
//
//  Created by Sun on 2019/3/14.
//

import Foundation

import SWCryptoKit
import SWExtensions

// MARK: - NetworkMessageParser

class NetworkMessageParser: INetworkMessageParser {
    // MARK: Properties

    private let magic: UInt32
    private var messageParsers = [String: IMessageParser]()

    // MARK: Lifecycle

    init(magic: UInt32) {
        self.magic = magic
    }

    // MARK: Functions

    func add(parser: IMessageParser) {
        messageParsers[parser.id] = parser
    }

    func parse(data: Data) -> NetworkMessage? {
        let byteStream = ByteStream(data)

        let magic = byteStream.read(UInt32.self).bigEndian
        guard self.magic == magic else {
            return nil
        }
        let command = byteStream.read(Data.self, count: 12).sw.to(type: String.self)
        let length = byteStream.read(UInt32.self)
        let checksum = byteStream.read(Data.self, count: 4)

        guard length <= byteStream.availableBytes else {
            return nil
        }
        let payload = byteStream.read(Data.self, count: Int(length))

        let checksumConfirm = Crypto.doubleSha256(payload).prefix(4)
        guard checksum == checksumConfirm else {
            return nil
        }

        let message = messageParsers[command]?.parse(data: payload) ?? UnknownMessage(data: payload)

        return NetworkMessage(magic: magic, command: command, length: length, checksum: checksum, message: message)
    }
}

// MARK: - AddressMessageParser

class AddressMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "addr" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)

        let count = byteStream.read(VarInt.self)

        var addressList = [NetworkAddress]()
        for _ in 0 ..< count.underlyingValue {
            _ = byteStream.read(UInt32.self) // Timestamp
            addressList.append(NetworkAddress(byteStream: byteStream))
        }

        return AddressMessage(addresses: addressList)
    }
}

// MARK: - GetDataMessageParser

class GetDataMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "getdata" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)

        let count = byteStream.read(VarInt.self)

        var inventoryItems = [InventoryItem]()
        for _ in 0 ..< count.underlyingValue {
            let type = byteStream.read(Int32.self)
            let hash = byteStream.read(Data.self, count: 32)
            let item = InventoryItem(type: type, hash: hash)
            inventoryItems.append(item)
        }

        return GetDataMessage(inventoryItems: inventoryItems)
    }
}

// MARK: - InventoryMessageParser

class InventoryMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "inv" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)

        let count = byteStream.read(VarInt.self)

        var inventoryItems = [InventoryItem]()
        var seen = Set<String>()

        for _ in 0 ..< Int(count.underlyingValue) {
            let item = InventoryItem(byteStream: byteStream)

            guard !seen.contains(item.hash.sw.reversedHex) else {
                continue
            }
            seen.insert(item.hash.sw.reversedHex)
            inventoryItems.append(item)
        }

        return InventoryMessage(inventoryItems: inventoryItems)
    }
}

// MARK: - PingMessageParser

class PingMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "ping" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)
        return PingMessage(nonce: byteStream.read(UInt64.self))
    }
}

// MARK: - PongMessageParser

class PongMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "pong" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)
        return PongMessage(nonce: byteStream.read(UInt64.self))
    }
}

// MARK: - VerackMessageParser

class VerackMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "verack" }

    // MARK: Functions

    func parse(data _: Data) -> IMessage {
        VerackMessage()
    }
}

// MARK: - VersionMessageParser

class VersionMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "version" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)

        let version = byteStream.read(Int32.self)
        let services = byteStream.read(UInt64.self)
        let timestamp = byteStream.read(Int64.self)
        let yourAddress = NetworkAddress(byteStream: byteStream)
        if byteStream.availableBytes == 0 {
            return VersionMessage(
                version: version,
                services: services,
                timestamp: timestamp,
                yourAddress: yourAddress,
                myAddress: nil,
                nonce: nil,
                userAgent: nil,
                startHeight: nil,
                relay: nil
            )
        }
        let myAddress = NetworkAddress(byteStream: byteStream)
        let nonce = byteStream.read(UInt64.self)
        let userAgent = byteStream.read(VarString.self)
        let startHeight = byteStream.read(Int32.self)
        let relay: Bool? = byteStream.availableBytes == 0 ? nil : byteStream.read(Bool.self)

        return VersionMessage(
            version: version,
            services: services,
            timestamp: timestamp,
            yourAddress: yourAddress,
            myAddress: myAddress,
            nonce: nonce,
            userAgent: userAgent,
            startHeight: startHeight,
            relay: relay
        )
    }
}

// MARK: - MemPoolMessageParser

class MemPoolMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "mempool" }

    // MARK: Functions

    func parse(data _: Data) -> IMessage {
        MemPoolMessage()
    }
}

// MARK: - MerkleBlockMessageParser

class MerkleBlockMessageParser: IMessageParser {
    // MARK: Properties

    private let blockHeaderParser: IBlockHeaderParser

    // MARK: Computed Properties

    var id: String { "merkleblock" }

    // MARK: Lifecycle

    init(blockHeaderParser: IBlockHeaderParser) {
        self.blockHeaderParser = blockHeaderParser
    }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)

        let blockHeader = blockHeaderParser.parse(byteStream: byteStream)

        let totalTransactions = byteStream.read(UInt32.self)
        let numberOfHashes = byteStream.read(VarInt.self)

        var hashes = [Data]()
        for _ in 0 ..< numberOfHashes.underlyingValue {
            hashes.append(byteStream.read(Data.self, count: 32))
        }

        let numberOfFlags = byteStream.read(VarInt.self)

        var flags = [UInt8]()
        for _ in 0 ..< numberOfFlags.underlyingValue {
            flags.append(byteStream.read(UInt8.self))
        }

        return MerkleBlockMessage(
            blockHeader: blockHeader,
            totalTransactions: totalTransactions,
            numberOfHashes: numberOfHashes,
            hashes: hashes,
            numberOfFlags: numberOfFlags,
            flags: flags
        )
    }
}

// MARK: - TransactionMessageParser

class TransactionMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "tx" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        TransactionMessage(transaction: TransactionSerializer.deserialize(data: data), size: data.count)
    }
}

// MARK: - RejectMessageParser

class RejectMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "reject" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        let byteStream = ByteStream(data)

        let message = byteStream.read(VarString.self)
        let ccode = byteStream.read(UInt8.self)
        let reason = byteStream.read(VarString.self)
        var data = Data()

        if message.value != "version" {
            data = byteStream.read(Data.self, count: 32)
        }

        return RejectMessage(message: message, ccode: ccode, reason: reason, data: data)
    }
}

// MARK: - UnknownMessageParser

class UnknownMessageParser: IMessageParser {
    // MARK: Computed Properties

    var id: String { "unknown" }

    // MARK: Functions

    func parse(data: Data) -> IMessage {
        UnknownMessage(data: data)
    }
}
