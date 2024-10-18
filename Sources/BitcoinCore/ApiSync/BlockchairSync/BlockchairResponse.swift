//
//  BlockchairResponse.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

import ObjectMapper

// MARK: - BlockchairResponse

enum BlockchairResponse {
    public static let dateStringToTimestampTransform: TransformOf<Int, String> = TransformOf(
        fromJSON: { string -> Int? in
            guard let string else {
                return nil
            }
            return dateFormatter.date(from: string).flatMap { Int($0.timeIntervalSince1970) }
        },
        toJSON: { (value: Int?) in
            guard let value else {
                return nil
            }
            return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(value)))
        }
    )

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - BlockchairTransactionsReponse

struct BlockchairTransactionsReponse: ImmutableMappable {
    // MARK: Nested Types

    struct ResponseData: ImmutableMappable {
        // MARK: Properties

        let addresses: [String: Address]
        let transactions: [Transaction]

        // MARK: Lifecycle

        init(map: Map) throws {
            addresses = try map.value("addresses")
            transactions = try map.value("transactions")
        }
    }

    struct ResponseContext: ImmutableMappable {
        // MARK: Properties

        let code: Int
        let limit: String
        let offset: String
        let results: Int
        let state: Int

        // MARK: Lifecycle

        init(map: Map) throws {
            code = try map.value("code")
            limit = try map.value("limit")
            offset = try map.value("offset")
            results = try map.value("results")
            state = try map.value("state")
        }
    }

    struct Transaction: ImmutableMappable, Hashable {
        // MARK: Properties

        let blockID: Int?
        let hash: String
        let balanceChange: Int
        let address: String

        // MARK: Lifecycle

        init(map: Map) throws {
            blockID = try map.value("block_id")
            hash = try map.value("hash")
            balanceChange = try map.value("balance_change")
            address = try map.value("address")
        }

        // MARK: Functions

        public func hash(into hasher: inout Hasher) {
            hasher.combine(hash)
        }
    }

    struct Address: ImmutableMappable {
        // MARK: Properties

        let script: String

        // MARK: Lifecycle

        init(map: Map) throws {
            script = try map.value("script_hex")
        }
    }

    // MARK: Properties

    let data: ResponseData
    let context: ResponseContext

    // MARK: Lifecycle

    init(map: Map) throws {
        data = try map.value("data")
        context = try map.value("context")
    }
}

// MARK: - BlockchairStatsReponse

struct BlockchairStatsReponse: ImmutableMappable {
    // MARK: Nested Types

    struct ResponseData: ImmutableMappable {
        // MARK: Properties

        let bestBlockHeight: Int
        let bestBlockHash: String
        let bestBlockTime: Int

        // MARK: Lifecycle

        init(map: Map) throws {
            bestBlockHeight = try map.value("best_block_height")
            bestBlockHash = try map.value("best_block_hash")
            bestBlockTime = try map.value("best_block_time", using: BlockchairResponse.dateStringToTimestampTransform)
        }
    }

    // MARK: Properties

    let data: ResponseData

    // MARK: Lifecycle

    init(map: Map) throws {
        data = try map.value("data")
    }
}

// MARK: - BlockchairBlocksResponse

struct BlockchairBlocksResponse: ImmutableMappable {
    // MARK: Nested Types

    struct BlockResponseMap: ImmutableMappable {
        // MARK: Properties

        let block: BlockResponse

        // MARK: Lifecycle

        init(map: Map) throws {
            block = try map.value("block")
        }
    }

    struct BlockResponse: ImmutableMappable {
        // MARK: Properties

        let hash: String

        // MARK: Lifecycle

        init(map: Map) throws {
            hash = try map.value("hash")
        }
    }

    // MARK: Properties

    let data: [String: BlockResponseMap]

    // MARK: Lifecycle

    init(map: Map) throws {
        data = try map.value("data")
    }
}

// MARK: - BlockchairBroadcastResponse

struct BlockchairBroadcastResponse: ImmutableMappable {
    // MARK: Nested Types

    struct ContextMap: ImmutableMappable {
        // MARK: Properties

        let code: Int
        let error: String?

        // MARK: Lifecycle

        init(map: Map) throws {
            code = try map.value("code")
            error = try map.value("error")
        }
    }

    // MARK: Properties

    let data: [String: String]?
    let context: ContextMap

    // MARK: Lifecycle

    init(map: Map) throws {
        data = try map.value("data")
        context = try map.value("context")
    }
}
