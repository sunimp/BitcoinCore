//
//  BlockchairApi.swift
//  BitcoinCore
//
//  Created by Sun on 2023/10/27.
//

import Foundation

import Alamofire
import ObjectMapper
import SWToolKit

public class BlockchairApi {
    // MARK: Properties

    private let baseURL = "https://api.blocksdecoded.com/v1/blockchair"
    private let chainID: String
    private let limit = 10000
    private let networkManager: NetworkManager

    // MARK: Lifecycle

    public init(chainID: String = "bitcoin", logger: Logger? = nil) {
        self.chainID = chainID
        networkManager = NetworkManager(logger: logger)
    }

    // MARK: Functions

    func transactions(addresses: [String], stopHeight: Int?) async throws -> [ApiTransactionItem] {
        var transactionItemsMap = [String: ApiTransactionItem]()

        for chunk in addresses.chunked(into: 100) {
            let (addressItems, transactions) = try await _transactions(addresses: chunk, stopHeight: stopHeight)

            for transaction in transactions {
                guard let blockHeight = transaction.blockID else {
                    continue
                }

                if transactionItemsMap[transaction.hash] == nil {
                    transactionItemsMap[transaction.hash] = ApiTransactionItem(
                        blockHash: "",
                        blockHeight: blockHeight,
                        apiAddressItems: []
                    )
                }

                if let addressItem = addressItems.first(where: { transaction.address == $0.address }) {
                    transactionItemsMap[transaction.hash]?.apiAddressItems.append(addressItem)
                }
            }
        }

        return Array(transactionItemsMap.values)
    }

    func lastBlockHeader() async throws -> ApiBlockHeaderItem {
        let parameters: Parameters = [
            "limit": "0",
        ]
        let url = "\(baseURL)/\(chainID)/stats"
        let response: BlockchairStatsReponse = try await networkManager.fetch(
            url: url,
            method: .get,
            parameters: parameters
        )

        return ApiBlockHeaderItem(
            hash: response.data.bestBlockHash.sw.reversedHexData!,
            height: response.data.bestBlockHeight,
            timestamp: response.data.bestBlockTime
        )
    }

    func blockHashes(heights: [Int]) async throws -> [Int: String] {
        var hashesMap = [Int: String]()

        for chunk in heights.chunked(into: 10) {
            let map = try await _blockHashes(heights: chunk)
            hashesMap.merge(map, uniquingKeysWith: { a, _ in a })
        }

        return hashesMap
    }

    func broadcastTransaction(hex: Data) async throws {
        let url = "https://api.blockchair.com/\(chainID)/push/transaction"
        let response: BlockchairBroadcastResponse = try await networkManager.fetch(
            url: url,
            method: .post,
            parameters: ["data": hex.sw.hex]
        )
        guard let data = response.data, data["transaction_hash"] != nil else {
            throw BitcoinCoreErrors.TransactionSendError.apiSendFailed(reason: response.context.error)
        }
    }

    private func _transactions(
        addresses: [String],
        stopHeight: Int? = nil,
        receivedScripts: [ApiAddressItem] = [],
        receivedTransactions: [BlockchairTransactionsReponse.Transaction] = []
    ) async throws
        -> ([ApiAddressItem], [BlockchairTransactionsReponse.Transaction]) {
        let parameters: Parameters = [
            "transaction_details": true,
            "limit": "\(limit),0",
            "offset": "\(receivedTransactions.count),0",
        ]
        let url = "\(baseURL)/\(chainID)/dashboards/addresses/\(addresses.joined(separator: ","))"

        do {
            let response: BlockchairTransactionsReponse = try await networkManager.fetch(
                url: url,
                method: .get,
                parameters: parameters
            )
            let scriptsSlice = response.data.addresses.map { ApiAddressItem(script: $0.value.script, address: $0.key) }
            let filteredTransactions = response.data.transactions.filter { transaction in
                if let height = transaction.blockID, let stopHeight {
                    stopHeight < height
                } else {
                    true
                }
            }
            let scriptsMerged = receivedScripts + scriptsSlice
            let transactionsMerged = receivedTransactions + filteredTransactions

            if filteredTransactions.count < limit {
                return (scriptsMerged, transactionsMerged)
            } else {
                return try await _transactions(
                    addresses: addresses,
                    stopHeight: stopHeight,
                    receivedScripts: scriptsMerged,
                    receivedTransactions: transactionsMerged
                )
            }
        } catch let responseError as SWToolKit.NetworkManager.ResponseError {
            if responseError.statusCode == 404 {
                return ([], [])
            } else {
                throw responseError
            }
        } catch {
            throw error
        }
    }

    private func _blockHashes(heights: [Int]) async throws -> [Int: String] {
        let parameters: Parameters = [
            "limit": "0",
        ]
        let heightsStr = heights.map { "\($0)" }.joined(separator: ",")
        let url = "\(baseURL)/\(chainID)/dashboards/blocks/\(heightsStr)"

        do {
            let response: BlockchairBlocksResponse = try await networkManager.fetch(
                url: url,
                method: .get,
                parameters: parameters
            )
            var map = [Int: String]()
            for (key, value) in response.data {
                guard let height = Int(key) else {
                    continue
                }
                map[height] = value.block.hash
            }

            return map
        } catch let responseError as SWToolKit.NetworkManager.ResponseError {
            if responseError.statusCode == 404 {
                return [:]
            } else {
                throw responseError
            }
        } catch {
            throw error
        }
    }
}
