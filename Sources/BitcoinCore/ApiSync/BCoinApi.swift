//
//  BCoinApi.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

import Alamofire
import ObjectMapper
import SWToolKit

// MARK: - BCoinApi

public class BCoinApi {
    // MARK: Properties

    private let url: String
    private let networkManager: NetworkManager

    // MARK: Lifecycle

    public init(url: String, logger: Logger? = nil) {
        self.url = url
        networkManager = NetworkManager(logger: logger)
    }
}

// MARK: IApiTransactionProvider

extension BCoinApi: IApiTransactionProvider {
    public func transactions(addresses: [String], stopHeight _: Int?) async throws -> [ApiTransactionItem] {
        let parameters: Parameters = [
            "addresses": addresses,
        ]
        let path = "/tx/address"

        let bcoinItems: [BCoinTransactionItem] = try await networkManager.fetch(
            url: url + path,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        return bcoinItems.compactMap { item -> ApiTransactionItem? in
            guard let blockHash = item.blockHash, let blockHeight = item.blockHeight else {
                return nil
            }

            return ApiTransactionItem(
                blockHash: blockHash, blockHeight: blockHeight,
                apiAddressItems: item.txOutputs.map { outputItem in
                    ApiAddressItem(script: outputItem.script, address: outputItem.address)
                }
            )
        }
    }
}

// MARK: - BCoinTransactionItem

open class BCoinTransactionItem: ImmutableMappable {
    // MARK: Properties

    public let blockHash: String?
    public let blockHeight: Int?
    public let txOutputs: [BCoinTransactionOutputItem]

    // MARK: Lifecycle

    public init(hash: String?, height: Int?, txOutputs: [BCoinTransactionOutputItem]) {
        blockHash = hash
        blockHeight = height
        self.txOutputs = txOutputs
    }

    public required init(map: Map) throws {
        blockHash = try? map.value("block")
        blockHeight = try? map.value("height")
        txOutputs = (try? map.value("outputs")) ?? []
    }

    // MARK: Static Functions

    static func == (lhs: BCoinTransactionItem, rhs: BCoinTransactionItem) -> Bool {
        lhs.blockHash == rhs.blockHash && lhs.blockHeight == rhs.blockHeight
    }
}

// MARK: - BCoinTransactionOutputItem

open class BCoinTransactionOutputItem: ImmutableMappable {
    // MARK: Properties

    public let script: String
    public let address: String?

    // MARK: Lifecycle

    public init(script: String, address: String?) {
        self.script = script
        self.address = address
    }

    public required init(map: Map) throws {
        script = try map.value("script")
        address = try map.value("address")
    }
}
