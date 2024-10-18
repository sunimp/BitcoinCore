//
//  BitcoinCore.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/3.
//

import Foundation

import BigInt
import HDWalletKit
import SWToolKit

// MARK: - BitcoinCore

public class BitcoinCore {
    // MARK: Properties

    // START: Extending

    public let peerGroup: IPeerGroup
    public let initialDownload: IInitialDownload
    public let transactionSyncer: ITransactionSyncer

    // END: Extending

    public var delegateQueue = DispatchQueue(label: "com.sunimp.bitcoin-core.bitcoin-core-delegate-queue")
    public weak var delegate: BitcoinCoreDelegate?

    let bloomFilterLoader: BloomFilterLoader
    let inventoryItemsHandlerChain = InventoryItemsHandlerChain()
    let peerTaskHandlerChain = PeerTaskHandlerChain()

    private let storage: IStorage
    private var dataProvider: IDataProvider
    private let publicKeyManager: IPublicKeyManager
    private let watchedTransactionManager: IWatchedTransactionManager
    private let addressConverter: AddressConverterChain
    private let restoreKeyConverterChain: RestoreKeyConverterChain
    private let unspentOutputSelector: UnspentOutputSelectorChain

    private let transactionCreator: ITransactionCreator?
    private let transactionBuilder: ITransactionBuilder?
    private let transactionFeeCalculator: ITransactionFeeCalculator?
    private let replacementTransactionBuilder: ReplacementTransactionBuilder?
    private let dustCalculator: IDustCalculator?
    private let paymentAddressParser: IPaymentAddressParser

    private let networkMessageSerializer: NetworkMessageSerializer
    private let networkMessageParser: NetworkMessageParser

    private let syncManager: SyncManager
    private let pluginManager: IPluginManager

    private let purpose: Purpose
    private let peerManager: IPeerManager

    // MARK: Lifecycle

    init(
        storage: IStorage,
        dataProvider: IDataProvider,
        peerGroup: IPeerGroup,
        initialDownload: IInitialDownload,
        bloomFilterLoader: BloomFilterLoader,
        transactionSyncer: ITransactionSyncer,
        publicKeyManager: IPublicKeyManager,
        addressConverter: AddressConverterChain,
        restoreKeyConverterChain: RestoreKeyConverterChain,
        unspentOutputSelector: UnspentOutputSelectorChain,
        transactionCreator: ITransactionCreator?,
        transactionFeeCalculator: ITransactionFeeCalculator?,
        transactionBuilder: ITransactionBuilder?,
        replacementTransactionBuilder: ReplacementTransactionBuilder?,
        dustCalculator: IDustCalculator?,
        paymentAddressParser: IPaymentAddressParser,
        networkMessageParser: NetworkMessageParser,
        networkMessageSerializer: NetworkMessageSerializer,
        syncManager: SyncManager,
        pluginManager: IPluginManager,
        watchedTransactionManager: IWatchedTransactionManager,
        purpose: Purpose,
        peerManager: IPeerManager
    ) {
        self.storage = storage
        self.dataProvider = dataProvider
        self.peerGroup = peerGroup
        self.initialDownload = initialDownload
        self.bloomFilterLoader = bloomFilterLoader
        self.transactionSyncer = transactionSyncer
        self.publicKeyManager = publicKeyManager
        self.addressConverter = addressConverter
        self.restoreKeyConverterChain = restoreKeyConverterChain
        self.unspentOutputSelector = unspentOutputSelector
        self.transactionCreator = transactionCreator
        self.transactionFeeCalculator = transactionFeeCalculator
        self.transactionBuilder = transactionBuilder
        self.replacementTransactionBuilder = replacementTransactionBuilder
        self.dustCalculator = dustCalculator
        self.paymentAddressParser = paymentAddressParser

        self.networkMessageParser = networkMessageParser
        self.networkMessageSerializer = networkMessageSerializer

        self.syncManager = syncManager
        self.pluginManager = pluginManager
        self.watchedTransactionManager = watchedTransactionManager

        self.purpose = purpose
        self.peerManager = peerManager
    }

    // MARK: Functions

    public func add(inventoryItemsHandler: IInventoryItemsHandler) {
        inventoryItemsHandlerChain.add(handler: inventoryItemsHandler)
    }

    public func add(peerTaskHandler: IPeerTaskHandler) {
        peerTaskHandlerChain.add(handler: peerTaskHandler)
    }

    public func add(restoreKeyConverter: IRestoreKeyConverter) {
        restoreKeyConverterChain.add(converter: restoreKeyConverter)
    }

    @discardableResult
    public func add(messageParser: IMessageParser) -> Self {
        networkMessageParser.add(parser: messageParser)
        return self
    }

    @discardableResult
    public func add(messageSerializer: IMessageSerializer) -> Self {
        networkMessageSerializer.add(serializer: messageSerializer)
        return self
    }

    public func add(plugin: IPlugin) {
        pluginManager.add(plugin: plugin)
    }

    public func prepend(addressConverter: IAddressConverter) {
        self.addressConverter.prepend(addressConverter: addressConverter)
    }

    public func prepend(unspentOutputSelector: IUnspentOutputSelector) {
        self.unspentOutputSelector.prepend(unspentOutputSelector: unspentOutputSelector)
    }

    func publicKey(byPath path: String) throws -> PublicKey {
        try publicKeyManager.publicKey(byPath: path)
    }
}

extension BitcoinCore {
    public func start() {
        syncManager.start()
    }

    func stop() {
        syncManager.stop()
    }
}

extension BitcoinCore {
    public var watchAccount: Bool { // TODO: What is better way to determine watch?
        transactionCreator == nil
    }

    public var lastBlockInfo: BlockInfo? {
        dataProvider.lastBlockInfo
    }

    public var balance: BalanceInfo {
        dataProvider.balance
    }

    public var syncState: BitcoinCore.KitState {
        syncManager.syncState
    }

    public func transactions(
        fromUid: String? = nil,
        type: TransactionFilterType?,
        limit: Int? = nil
    )
        -> [TransactionInfo] {
        dataProvider.transactions(fromUid: fromUid, type: type, limit: limit)
    }

    public func transaction(hash: String) -> TransactionInfo? {
        dataProvider.transaction(hash: hash)
    }

    public func unspentOutputs(filters: UtxoFilters) -> [UnspentOutput] {
        unspentOutputSelector.all(filters: filters)
    }

    public func unspentOutputsInfo(filters: UtxoFilters) -> [UnspentOutputInfo] {
        unspentOutputSelector.all(filters: filters).map {
            .init(
                outputIndex: $0.output.index,
                transactionHash: $0.output.transactionHash,
                timestamp: TimeInterval($0.transaction.timestamp),
                address: $0.output.address,
                value: $0.output.value
            )
        }
    }

    public func address(fromHash hash: Data, scriptType: ScriptType) throws -> Address {
        try addressConverter.convert(lockingScriptPayload: hash, type: scriptType)
    }

    public func send(params: SendParameters) throws -> FullTransaction {
        guard let transactionCreator else {
            throw CoreError.readOnlyCore
        }

        return try transactionCreator.create(params: params)
    }

    func redeem(from unspentOutput: UnspentOutput, params: SendParameters) throws -> FullTransaction {
        guard let transactionCreator else {
            throw CoreError.readOnlyCore
        }

        return try transactionCreator.create(from: unspentOutput, params: params)
    }

    public func createRawTransaction(params: SendParameters) throws -> Data {
        guard let transactionCreator else {
            throw CoreError.readOnlyCore
        }

        return try transactionCreator.createRawTransaction(params: params)
    }

    public func validate(address: String, pluginData: [UInt8: IPluginData] = [:]) throws {
        try pluginManager.validate(address: addressConverter.convert(address: address), pluginData: pluginData)
    }

    public func parse(paymentAddress: String) -> BitcoinPaymentData {
        paymentAddressParser.parse(paymentAddress: paymentAddress)
    }

    public func sendInfo(params: SendParameters) throws -> BitcoinSendInfo {
        guard let transactionFeeCalculator else {
            throw CoreError.readOnlyCore
        }

//        if let t = try transactionBuilder?.buildTransaction(params: params) {
//            print(TransactionSerializer.serialize(transaction: t.build()).sw.hex)
//        }
        return try transactionFeeCalculator.sendInfo(params: params)
    }

    public func maxSpendableValue(params: SendParameters) throws -> Int {
        guard let transactionFeeCalculator else {
            throw CoreError.readOnlyCore
        }

        let outputs = params.unspentOutputs
            .map { $0.outputs(from: unspentOutputSelector.all(filters: params.utxoFilters)) }
        let balance = outputs.map { $0.map(\.output.value).reduce(0, +) } ?? balance.spendable

        params.value = balance
        params.senderPay = false
        let sendAllFee = try transactionFeeCalculator.sendInfo(params: params).fee

        return max(0, balance - sendAllFee)
    }

    public func minSpendableValue(params: SendParameters) throws -> Int {
        guard let dustCalculator else {
            throw CoreError.readOnlyCore
        }

        var scriptType = ScriptType.p2pkh
        if let address = params.address, let address = try? addressConverter.convert(address: address) {
            scriptType = address.scriptType
        }

        return dustCalculator.dust(type: scriptType, dustThreshold: params.dustThreshold)
    }

    public func maxSpendLimit(pluginData: [UInt8: IPluginData]) throws -> Int? {
        try pluginManager.maxSpendLimit(pluginData: pluginData)
    }

    public func receiveAddress() -> String {
        guard
            let publicKey = try? publicKeyManager.receivePublicKey(),
            let address = try? addressConverter.convert(publicKey: publicKey, type: purpose.scriptType)
        else {
            return ""
        }

        return address.stringValue
    }

    public func address(from publicKey: PublicKey) throws -> Address {
        try addressConverter.convert(publicKey: publicKey, type: purpose.scriptType)
    }

    public func changePublicKey() throws -> PublicKey {
        try publicKeyManager.changePublicKey()
    }

    public func receivePublicKey() throws -> PublicKey {
        try publicKeyManager.receivePublicKey()
    }

    public func usedAddresses(change: Bool) -> [UsedAddress] {
        publicKeyManager.usedPublicKeys(change: change).compactMap { pubKey in
            let address = try? addressConverter.convert(publicKey: pubKey, type: purpose.scriptType)
            return address.map { UsedAddress(index: pubKey.index, address: $0.stringValue) }
        }
    }

    func watch(transaction: BitcoinCore.TransactionFilter, delegate: IWatchedTransactionDelegate) {
        watchedTransactionManager.add(transactionFilter: transaction, delegatedTo: delegate)
    }

    public func replacementTransaction(
        transactionHash: String,
        minFee: Int,
        type: ReplacementType
    ) throws
        -> ReplacementTransaction {
        guard let replacementTransactionBuilder else {
            throw CoreError.readOnlyCore
        }

        let (mutableTransaction, fullInfo, descendantTransactionHashes) = try replacementTransactionBuilder
            .replacementTransaction(
                transactionHash: transactionHash,
                minFee: minFee,
                type: type
            )
        let info = dataProvider.transactionInfo(from: fullInfo)

        return ReplacementTransaction(
            mutableTransaction: mutableTransaction,
            info: info,
            replacedTransactionHashes: descendantTransactionHashes
        )
    }

    public func send(replacementTransaction: ReplacementTransaction) throws -> FullTransaction {
        guard let transactionCreator else {
            throw CoreError.readOnlyCore
        }

        return try transactionCreator.create(from: replacementTransaction.mutableTransaction)
    }

    public func replacmentTransactionInfo(
        transactionHash: String,
        type: ReplacementType
    )
        -> (originalTransactionSize: Int, feeRange: Range<Int>)? {
        replacementTransactionBuilder?.replacementInfo(transactionHash: transactionHash, type: type)
    }

    public func debugInfo(network: INetwork) -> String {
        dataProvider.debugInfo(network: network, scriptType: purpose.scriptType, addressConverter: addressConverter)
    }

    public var statusInfo: [(String, Any)] {
        var status = [(String, Any)]()
        status.append(("sync mode", syncManager.syncMode.description))
        status.append(("state", syncManager.syncState.toString()))
        status.append((
            "synced until",
            ((lastBlockInfo?.timestamp.map { Double($0) })?.map { Date(timeIntervalSince1970: $0) }) ?? "n/a"
        ))
        status.append(("syncing peer", initialDownload.syncPeer?.host ?? "n/a"))
        status.append(("derivation", purpose.description))

        status.append(
            contentsOf:
            peerManager.connected.enumerated().map { index, peer in
                var peerStatus = [(String, Any)]()
                peerStatus.append(("status", initialDownload.isSynced(peer: peer) ? "synced" : "not synced"))
                peerStatus.append(("host", peer.host))
                peerStatus.append(("best block", peer.announcedLastBlockHeight))
                peerStatus.append(("user agent", peer.subVersion))

                let tasks = peer.tasks
                if tasks.isEmpty {
                    peerStatus.append(("tasks", "no tasks"))
                } else {
                    peerStatus.append(("tasks", tasks.map { task in
                        (String(describing: task), task.state)
                    }))
                }

                return ("peer \(index + 1)", peerStatus)
            }
        )

        return status
    }

    func rawTransaction(transactionHash: String) -> String? {
        dataProvider.rawTransaction(transactionHash: transactionHash)
    }
}

// MARK: IDataProviderDelegate

extension BitcoinCore: IDataProviderDelegate {
    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        delegateQueue.async { [weak self] in
            if let kit = self {
                kit.delegate?.transactionsUpdated(inserted: inserted, updated: updated)
            }
        }
    }

    func transactionsDeleted(hashes: [String]) {
        delegateQueue.async { [weak self] in
            self?.delegate?.transactionsDeleted(hashes: hashes)
        }
    }

    func balanceUpdated(balance: BalanceInfo) {
        delegateQueue.async { [weak self] in
            if let kit = self {
                kit.delegate?.balanceUpdated(balance: balance)
            }
        }
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        delegateQueue.async { [weak self] in
            if let kit = self {
                kit.delegate?.lastBlockInfoUpdated(lastBlockInfo: lastBlockInfo)
            }
        }
    }
}

// MARK: ISyncManagerDelegate

extension BitcoinCore: ISyncManagerDelegate {
    func kitStateUpdated(state: KitState) {
        delegateQueue.async { [weak self] in
            self?.delegate?.kitStateUpdated(state: state)
        }
    }
}

// MARK: - BitcoinCoreDelegate

public protocol BitcoinCoreDelegate: AnyObject {
    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo])
    func transactionsDeleted(hashes: [String])
    func balanceUpdated(balance: BalanceInfo)
    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo)
    func kitStateUpdated(state: BitcoinCore.KitState)
}

extension BitcoinCoreDelegate {
    public func transactionsUpdated(inserted _: [TransactionInfo], updated _: [TransactionInfo]) { }
    public func transactionsDeleted(hashes _: [String]) { }
    public func balanceUpdated(balance _: BalanceInfo) { }
    public func lastBlockInfoUpdated(lastBlockInfo _: BlockInfo) { }
    public func kitStateUpdated(state _: BitcoinCore.KitState) { }
}

extension BitcoinCore {
    public enum KitState {
        case synced
        case apiSyncing(transactions: Int)
        case syncing(progress: Double)
        case notSynced(error: Error)

        // MARK: Functions

        func toString() -> String {
            switch self {
            case .synced: "Synced"
            case let .apiSyncing(transactions): "ApiSyncing-\(transactions)"
            case let .syncing(progress): "Syncing-\(Int(progress * 100))"
            case let .notSynced(error): "NotSynced-\(String(reflecting: error))"
            }
        }
    }

    public enum SyncMode: Equatable {
        case blockchair // Restore and sync from Blockchair API.
        case api // Restore and sync from API.
        case full // Sync from bip44Checkpoint. Api restore disabled

        // MARK: Computed Properties

        var description: String {
            switch self {
            case .blockchair: "Blockchair API"
            case .api: "Hybrid"
            case .full: "Blockchain"
            }
        }
    }

    public enum SendType {
        case p2p
        case api(blockchairApi: BlockchairApi)
    }

    public enum TransactionFilter {
        case p2shOutput(scriptHash: Data)
        case outpoint(transactionHash: Data, outputIndex: Int)
    }
}

// MARK: - BitcoinCore.KitState + Equatable

extension BitcoinCore.KitState: Equatable {
    public static func == (lhs: BitcoinCore.KitState, rhs: BitcoinCore.KitState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced):
            true
        case let (.apiSyncing(transactions: leftCount), .apiSyncing(transactions: rightCount)):
            leftCount == rightCount
        case let (.syncing(progress: leftProgress), .syncing(progress: rightProgress)):
            leftProgress == rightProgress
        case let (.notSynced(lhsError), .notSynced(rhsError)):
            "\(lhsError)" == "\(rhsError)"
        default:
            false
        }
    }
}

extension BitcoinCore {
    public enum CoreError: Error {
        case readOnlyCore
    }

    public enum StateError: Error {
        case notStarted
    }
}

extension BitcoinCore {
    public static func firstAddress(
        seed: Data,
        purpose: Purpose,
        network: INetwork,
        addressCoverter: AddressConverterChain
    ) throws
        -> Address {
        let wallet = HDWallet(seed: seed, coinType: network.coinType, xPrivKey: network.xPrivKey, purpose: purpose)
        let publicKey: PublicKey = try wallet.publicKey(account: 0, index: 0, external: true)

        return try addressCoverter.convert(publicKey: publicKey, type: purpose.scriptType)
    }

    public static func firstAddress(
        extendedKey: HDExtendedKey,
        purpose: Purpose,
        network: INetwork,
        addressCoverter: AddressConverterChain
    ) throws
        -> Address {
        let publicKey: PublicKey
        switch extendedKey {
        case let .private(key: privateKey):
            switch extendedKey.derivedType {
            case .master:
                let wallet = HDWallet(masterKey: privateKey, coinType: network.coinType, purpose: purpose)
                publicKey = try wallet.publicKey(account: 0, index: 0, external: true)

            case .account:
                let wallet = HDAccountWallet(privateKey: privateKey)
                publicKey = try wallet.publicKey(index: 0, external: true)

            case .bip32:
                throw BitcoinCoreBuilder.BuildError.notSupported
            }

        case let .public(key: hdPublicKey):
            let wallet = HDWatchAccountWallet(publicKey: hdPublicKey)
            publicKey = try wallet.publicKey(index: 0, external: true)
        }

        return try addressCoverter.convert(publicKey: publicKey, type: purpose.scriptType)
    }
}

// MARK: - SendParameters

public class SendParameters {
    // MARK: Properties

    public var address: String?
    public var value: Int?
    public var feeRate: Int?
    public var sortType: TransactionDataSortType
    public var senderPay: Bool
    public var rbfEnabled: Bool
    public var memo: String?
    public var unspentOutputs: [UnspentOutputInfo]?
    public var pluginData: [UInt8: IPluginData]
    public var dustThreshold: Int?
    public var utxoFilters: UtxoFilters
    public var maxOutputsCountForInputs: Int?
    public var changeToFirstInput: Bool

    // MARK: Lifecycle

    public init(
        address: String? = nil, value: Int? = nil, feeRate: Int? = nil, sortType: TransactionDataSortType = .none,
        senderPay: Bool = true, rbfEnabled: Bool = true, memo: String? = nil,
        unspentOutputs: [UnspentOutputInfo]? = nil, pluginData: [UInt8: IPluginData] = [:],
        dustThreshold: Int? = nil, utxoFilters: UtxoFilters = UtxoFilters(), changeToFirstInput: Bool = false
    ) {
        self.address = address
        self.value = value
        self.feeRate = feeRate
        self.sortType = sortType
        self.senderPay = senderPay
        self.rbfEnabled = rbfEnabled
        self.memo = memo
        self.unspentOutputs = unspentOutputs
        self.pluginData = pluginData
        self.dustThreshold = dustThreshold
        self.utxoFilters = utxoFilters
        self.changeToFirstInput = changeToFirstInput
    }
}

// MARK: - UtxoFilters

public struct UtxoFilters {
    // MARK: Properties

    public let scriptTypes: [ScriptType]?
    public let maxOutputsCountForInputs: Int?

    // MARK: Lifecycle

    public init(scriptTypes: [ScriptType]? = nil, maxOutputsCountForInputs: Int? = nil) {
        self.scriptTypes = scriptTypes
        self.maxOutputsCountForInputs = maxOutputsCountForInputs
    }
}
