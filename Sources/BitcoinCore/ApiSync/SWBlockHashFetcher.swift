//
//  SWBlockHashFetcher.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

import Alamofire
import ObjectMapper
import SWToolKit

// MARK: - SWBlockHashFetcher

public class SWBlockHashFetcher: IBlockHashFetcher {
    // MARK: Static Properties

    private static let paginationLimit = 100

    // MARK: Properties

    private let wwURL: String
    private let networkManager: NetworkManager

    // MARK: Lifecycle

    public init(wwURL: String, logger: Logger? = nil) {
        self.wwURL = wwURL
        networkManager = NetworkManager(logger: logger)
    }

    // MARK: Functions

    public func fetch(heights: [Int]) async throws -> [Int: String] {
        let parameters: Parameters = [
            "numbers": heights.map { String($0) }.joined(separator: ","),
        ]

        let blockResponses: [BlockResponse] = try await networkManager.fetch(
            url: "\(wwURL)/hashes",
            method: .get,
            parameters: parameters
        )
        var hashes = [Int: String]()

        for response in blockResponses {
            hashes[response.height] = response.hash
        }

        return hashes
    }
}

// MARK: - BlockResponse

struct BlockResponse: ImmutableMappable {
    // MARK: Properties

    let height: Int
    let hash: String

    // MARK: Lifecycle

    init(map: Map) throws {
        height = try map.value("number")
        hash = try map.value("hash")
    }
}
