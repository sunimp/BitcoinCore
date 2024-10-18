//
//  Protocols.swift
//  BitcoinCore
//
//  Created by Sun on 2018/10/18.
//

import Combine
import Foundation

import BigInt
import NIO
import SWToolKit

// MARK: - BlockValidatorType

enum BlockValidatorType { case header, bits, legacy, testNet, EDA, DAA, DGW }

// MARK: - IPublicKeyFetcher

protocol IPublicKeyFetcher {
    func publicKeys(indices: Range<UInt32>, external: Bool) throws -> [PublicKey]
}

// MARK: - IDifficultyEncoder

public protocol IDifficultyEncoder {
    func compactFrom(hash: Data) -> Int
    func decodeCompact(bits: Int) -> BigInt
    func encodeCompact(from bigInt: BigInt) -> Int
}

// MARK: - IBlockValidatorHelper

public protocol IBlockValidatorHelper {
    func previous(for block: Block, count: Int) -> Block?
    func previousWindow(for block: Block, count: Int) -> [Block]?
}

// MARK: - IBlockValidator

public protocol IBlockValidator: AnyObject {
    func validate(block: Block, previousBlock: Block) throws
}

// MARK: - IBlockChainedValidator

public protocol IBlockChainedValidator: IBlockValidator {
    func isBlockValidatable(block: Block, previousBlock: Block) -> Bool
}

// MARK: - IHDWallet

protocol IHDWallet {
    func publicKey(account: Int, index: Int, external: Bool) throws -> PublicKey
    func publicKeys(account: Int, indices: Range<UInt32>, external: Bool) throws -> [PublicKey]
}

// MARK: - IPrivateHDWallet

protocol IPrivateHDWallet {
    func privateKeyData(account: Int, index: Int, external: Bool) throws -> Data
}

// MARK: - IApiConfigProvider

protocol IApiConfigProvider {
    var reachabilityHost: String { get }
    var apiURL: String { get }
}

// MARK: - IPeerAddressManager

protocol IPeerAddressManager: AnyObject {
    var delegate: IPeerAddressManagerDelegate? { get set }
    var ip: String? { get }
    var hasFreshIps: Bool { get }
    func markSuccess(ip: String)
    func markFailed(ip: String)
    func add(ips: [String])
    func markConnected(peer: IPeer)
}

// MARK: - IApiSyncStateManager

protocol IApiSyncStateManager: AnyObject {
    var restored: Bool { get set }
}

// MARK: - IOutputStorage

public protocol IOutputStorage {
    func previousOutput(ofInput: Input) -> Output?
    func outputsWithPublicKeys() -> [OutputWithPublicKey]
}

// MARK: - IStorage

public protocol IStorage: IOutputStorage {
    var initialRestored: Bool? { get }
    func set(initialRestored: Bool)

    func leastScoreFastestPeerAddress(excludingIps: [String]) -> PeerAddress?
    func peerAddressExist(address: String) -> Bool
    func save(peerAddresses: [PeerAddress])
    func deletePeerAddress(byIp ip: String)
    func set(connectionTime: Double, toPeerAddress: String)

    var apiBlockHashesCount: Int { get }
    var blockchainBlockHashes: [BlockHash] { get }
    var lastBlockchainBlockHash: BlockHash? { get }
    func blockHashHeaderHashes(except: [Data]) -> [Data]
    var blockHashHeaderHashes: [Data] { get }
    var lastBlockHash: BlockHash? { get }
    var blockHashPublicKeys: [BlockHashPublicKey] { get }
    func blockHashesSortedBySequenceAndHeight(limit: Int) -> [BlockHash]
    func add(blockHashes: [BlockHash])
    func add(blockHashPublicKeys: [BlockHashPublicKey])
    func deleteBlockHash(byHash: Data)
    func deleteBlockchainBlockHashes()
    func deleteUselessBlocks(before: Int)
    func releaseMemory()

    var blocksCount: Int { get }
    var lastBlock: Block? { get }
    var downloadedTransactionsBestBlockHeight: Int { get }
    func blocksCount(headerHashes: [Data]) -> Int
    func update(block: Block)
    func save(block: Block)
    func blocks(heightGreaterThan: Int, sortedBy: Block.Columns, limit: Int) -> [Block]
    func blocks(from startHeight: Int, to endHeight: Int, ascending: Bool) -> [Block]
    func blocks(byHexes: [Data]) -> [Block]
    func blocks(heightGreaterThanOrEqualTo: Int, stale: Bool) -> [Block]
    func blocks(stale: Bool) -> [Block]
    func blockByHeightStalePrioritized(height: Int) -> Block?
    func block(byHeight: Int) -> Block?
    func block(byHash: Data) -> Block?
    func block(stale: Bool, sortedHeight: String) -> Block?
    func add(block: Block) throws
    func setBlockPartial(hash: Data) throws
    func delete(blocks: [Block]) throws
    func unstaleAllBlocks() throws
    func timestamps(from startHeight: Int, to endHeight: Int) -> [Int]

    func transactionExists(byHash: Data) -> Bool
    func fullTransaction(byHash hash: Data) -> FullTransaction?
    func transaction(byHash: Data) -> Transaction?
    func invalidTransaction(byHash: Data) -> InvalidTransaction?
    func validOrInvalidTransaction(byUid: String) -> Transaction?
    func incomingPendingTransactionHashes() -> [Data]
    func incomingPendingTransactionsExist() -> Bool
    func inputs(byHashes hashes: [Data]) -> [Input]
    func transactions(ofBlock: Block) -> [Transaction]
    func transactions(hashes: [Data]) -> [Transaction]
    func fullTransactions(from: [Transaction]) -> [FullTransaction]
    func descendantTransactionsFullInfo(of transactionHash: Data) -> [FullTransactionForInfo]
    func descendantTransactions(of transactionHash: Data) -> [Transaction]
    func newTransactions() -> [FullTransaction]
    func newTransaction(byHash: Data) -> Transaction?
    func relayedTransactionExists(byHash: Data) -> Bool
    func add(transaction: FullTransaction) throws
    func update(transaction: FullTransaction) throws
    func update(transaction: Transaction) throws
    func fullInfo(forTransactions: [TransactionWithBlock]) -> [FullTransactionForInfo]
    func validOrInvalidTransactionsFullInfo(
        fromTimestamp: Int?,
        fromOrder: Int?,
        type: TransactionFilterType?,
        limit: Int?
    )
        -> [FullTransactionForInfo]
    func transactionFullInfo(byHash hash: Data) -> FullTransactionForInfo?
    func moveTransactionsTo(invalidTransactions: [InvalidTransaction]) throws
    func move(invalidTransaction: InvalidTransaction, toTransactions: FullTransaction) throws

    func unspentOutputs() -> [UnspentOutput]
    func inputs(transactionHash: Data) -> [Input]
    func outputs(transactionHash: Data) -> [Output]
    func outputsCount(transactionHash: Data) -> Int
    func inputsUsingOutputs(withTransactionHash: Data) -> [Input]
    func inputsUsing(previousOutputTxHash: Data, previousOutputIndex: Int) -> [Input]

    func sentTransaction(byHash: Data) -> SentTransaction?
    func update(sentTransaction: SentTransaction)
    func delete(sentTransaction: SentTransaction)
    func add(sentTransaction: SentTransaction)

    func publicKeys() -> [PublicKey]
    func publicKey(raw: Data) -> PublicKey?
    func publicKey(hashP2pkh: Data) -> PublicKey?
    func publicKey(hashP2wpkhWrappedInP2sh: Data) -> PublicKey?
    func publicKey(convertedForP2tr: Data) -> PublicKey?
    func add(publicKeys: [PublicKey])
    func publicKeysWithUsedState() -> [PublicKeyWithUsedState]
    func publicKey(byPath: String) -> PublicKey?
}

// MARK: - IRestoreKeyConverter

public protocol IRestoreKeyConverter {
    func keysForApiRestore(publicKey: PublicKey) -> [String]
    func bloomFilterElements(publicKey: PublicKey) -> [Data]
}

// MARK: - IPublicKeyManager

public protocol IPublicKeyManager {
    func usedPublicKeys(change: Bool) -> [PublicKey]
    func changePublicKey() throws -> PublicKey
    func receivePublicKey() throws -> PublicKey
    func fillGap() throws
    func addKeys(keys: [PublicKey])
    func gapShifts() -> Bool
    func publicKey(byPath: String) throws -> PublicKey
}

// MARK: - IBloomFilterManagerDelegate

public protocol IBloomFilterManagerDelegate: AnyObject {
    func bloomFilterUpdated(bloomFilter: BloomFilter)
}

// MARK: - IBloomFilterManager

public protocol IBloomFilterManager: AnyObject {
    var delegate: IBloomFilterManagerDelegate? { get set }
    var bloomFilter: BloomFilter? { get }
    func regenerateBloomFilter()
}

// MARK: - IPeerGroup

public protocol IPeerGroup: AnyObject {
    var publisher: AnyPublisher<PeerGroupEvent, Never> { get }
    var started: Bool { get }

    func start()
    func stop()
    func refresh()
    func reconnectPeers()

    func isReady(peer: IPeer) -> Bool
}

// MARK: - IPeerManager

protocol IPeerManager: AnyObject {
    var totalPeersCount: Int { get }
    var connected: [IPeer] { get }
    var sorted: [IPeer] { get }
    var readyPeers: [IPeer] { get }
    func add(peer: IPeer)
    func peerDisconnected(peer: IPeer)
    func disconnectAll()
}

// MARK: - IPeer

public protocol IPeer: AnyObject {
    var delegate: PeerDelegate? { get set }
    var localBestBlockHeight: Int32 { get set }
    var announcedLastBlockHeight: Int32 { get }
    var subVersion: String { get }
    var host: String { get }
    var logName: String { get }
    var ready: Bool { get }
    var connected: Bool { get }
    var connectionTime: Double { get }
    var tasks: [PeerTask] { get }
    func connect()
    func disconnect(error: Error?)
    func add(task: PeerTask)
    func filterLoad(bloomFilter: BloomFilter)
    func sendMempoolMessage()
    func sendPing(nonce: UInt64)
    func equalTo(_ peer: IPeer?) -> Bool
}

// MARK: - PeerDelegate

public protocol PeerDelegate: AnyObject {
    func peerReady(_ peer: IPeer)
    func peerBusy(_ peer: IPeer)
    func peerDidConnect(_ peer: IPeer)
    func peerDidDisconnect(_ peer: IPeer, withError error: Error?)

    func peer(_ peer: IPeer, didCompleteTask task: PeerTask)
    func peer(_ peer: IPeer, didReceiveMessage message: IMessage)
}

// MARK: - IPeerTaskRequester

public protocol IPeerTaskRequester: AnyObject {
    var protocolVersion: Int32 { get }
    func send(message: IMessage)
}

// MARK: - IPeerTaskDelegate

public protocol IPeerTaskDelegate: AnyObject {
    func handle(completedTask task: PeerTask)
    func handle(failedTask task: PeerTask, error: Error)
}

// MARK: - IPeerConnection

protocol IPeerConnection: AnyObject {
    var delegate: PeerConnectionDelegate? { get set }
    var host: String { get }
    var port: Int { get }
    var logName: String { get }
    func connect()
    func disconnect(error: Error?)
    func send(message: IMessage)
}

// MARK: - IConnectionTimeoutManager

protocol IConnectionTimeoutManager: AnyObject {
    func reset()
    func timePeriodPassed(peer: IPeer)
}

// MARK: - IBlockSyncListener

public protocol IBlockSyncListener: AnyObject {
    func blocksSyncFinished()
    func currentBestBlockHeightUpdated(height: Int32, maxBlockHeight: Int32)
    func blockForceAdded()
}

// MARK: - IBlockHashFetcher

public protocol IBlockHashFetcher {
    func fetch(heights: [Int]) async throws -> [Int: String]
}

// MARK: - IPeerAddressManagerDelegate

protocol IPeerAddressManagerDelegate: AnyObject {
    func newIpsAdded()
}

// MARK: - IPeerDiscovery

protocol IPeerDiscovery {
    var peerAddressManager: IPeerAddressManager? { get set }
    func lookup(dnsSeeds: [String])
}

// MARK: - IFactory

protocol IFactory {
    func block(withHeader header: BlockHeader, previousBlock: Block) -> Block
    func block(withHeader header: BlockHeader, height: Int) -> Block
    func blockHash(withHeaderHash headerHash: Data, height: Int, order: Int) -> BlockHash
    func peer(withHost host: String, eventLoopGroup: MultiThreadedEventLoopGroup, logger: Logger?) -> IPeer
    func transaction(version: Int, lockTime: Int) -> Transaction
    func inputToSign(withPreviousOutput: UnspentOutput, script: Data, sequence: Int) -> InputToSign
    func output(withIndex index: Int, address: Address, value: Int, publicKey: PublicKey?) -> Output
    func nullDataOutput(data: Data) -> Output
    func bloomFilter(withElements: [Data]) -> BloomFilter
}

// MARK: - IApiTransactionProvider

public protocol IApiTransactionProvider {
    func transactions(addresses: [String], stopHeight: Int?) async throws -> [ApiTransactionItem]
}

// MARK: - ISyncManager

protocol ISyncManager {
    func start()
    func stop()
}

// MARK: - IApiSyncer

protocol IApiSyncer {
    var listener: IApiSyncerListener? { get set }
    var willSync: Bool { get }
    func sync()
    func terminate()
}

// MARK: - IHasher

public protocol IHasher {
    func hash(data: Data) -> Data
}

// MARK: - IApiSyncerListener

protocol IApiSyncerListener: AnyObject {
    func onSyncSuccess()
    func transactionsFound(count: Int)
    func onSyncFailed(error: Error)
}

// MARK: - IPaymentAddressParser

protocol IPaymentAddressParser {
    func parse(paymentAddress: String) -> BitcoinPaymentData
}

// MARK: - IAddressConverter

public protocol IAddressConverter {
    func convert(address: String) throws -> Address
    func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address
    func convert(publicKey: PublicKey, type: ScriptType) throws -> Address
}

// MARK: - IScriptConverter

public protocol IScriptConverter {
    func decode(data: Data) throws -> Script
}

// MARK: - IScriptExtractor

protocol IScriptExtractor: AnyObject {
    var type: ScriptType { get }
    func extract(from data: Data, converter: IScriptConverter) throws -> Data?
}

// MARK: - IOutputsCache

protocol IOutputsCache: AnyObject {
    func add(outputs: [Output])
    func valueSpent(by input: Input) -> Int?
    func clear()
}

// MARK: - ITransactionInvalidator

protocol ITransactionInvalidator {
    func invalidate(transaction: Transaction)
}

// MARK: - ITransactionConflictsResolver

protocol ITransactionConflictsResolver {
    func transactionsConflicting(withInblockTransaction transaction: FullTransaction) -> [Transaction]
    func transactionsConflicting(withPendingTransaction transaction: FullTransaction) -> [Transaction]
    func incomingPendingTransactionsConflicting(with transaction: FullTransaction) -> [Transaction]
    func isTransactionReplaced(transaction: FullTransaction) -> Bool
}

// MARK: - IBlockTransactionProcessor

public protocol IBlockTransactionProcessor: AnyObject {
    var listener: IBlockchainDataListener? { get set }

    func processReceived(transactions: [FullTransaction], inBlock block: Block, skipCheckBloomFilter: Bool) throws
}

// MARK: - IPendingTransactionProcessor

public protocol IPendingTransactionProcessor: AnyObject {
    var listener: IBlockchainDataListener? { get set }

    func processReceived(transactions: [FullTransaction], skipCheckBloomFilter: Bool) throws
    func processCreated(transaction: FullTransaction) throws
}

// MARK: - ITransactionExtractor

protocol ITransactionExtractor {
    func extract(transaction: FullTransaction)
}

// MARK: - ITransactionLinker

protocol ITransactionLinker {
    func handle(transaction: FullTransaction)
}

// MARK: - ITransactionSyncer

public protocol ITransactionSyncer: AnyObject {
    func newTransactions() -> [FullTransaction]
    func handleRelayed(transactions: [FullTransaction])
    func handleInvalid(fullTransaction: FullTransaction)
    func shouldRequestTransaction(hash: Data) -> Bool
}

// MARK: - ITransactionCreator

public protocol ITransactionCreator {
    func create(params: SendParameters) throws -> FullTransaction
    func create(from: UnspentOutput, params: SendParameters) throws -> FullTransaction
    func create(from mutableTransaction: MutableTransaction) throws -> FullTransaction
    func createRawTransaction(params: SendParameters) throws -> Data
}

// MARK: - ITransactionBuilder

protocol ITransactionBuilder {
    func buildTransaction(params: SendParameters) throws -> MutableTransaction
    func buildTransaction(from: UnspentOutput, params: SendParameters) throws -> MutableTransaction
}

// MARK: - ITransactionFeeCalculator

protocol ITransactionFeeCalculator {
    func sendInfo(params: SendParameters) throws -> BitcoinSendInfo
}

// MARK: - IBlockchain

protocol IBlockchain {
    var listener: IBlockchainDataListener? { get set }

    func connect(merkleBlock: MerkleBlock) throws -> Block
    func forceAdd(merkleBlock: MerkleBlock, height: Int) throws -> Block
    func handleFork() throws
    func deleteBlocks(blocks: [Block]) throws
}

// MARK: - IBlockchainDataListener

public protocol IBlockchainDataListener: AnyObject {
    func onUpdate(updated: [Transaction], inserted: [Transaction], inBlock: Block?)
    func onDelete(transactionHashes: [String])
    func onInsert(block: Block)
}

// MARK: - IInputSigner

protocol IInputSigner {
    func sigScriptData(transaction: Transaction, inputsToSign: [InputToSign], outputs: [Output], index: Int) throws
        -> [Data]
}

// MARK: - ITransactionSizeCalculator

public protocol ITransactionSizeCalculator {
    func transactionSize(previousOutputs: [Output], outputScriptTypes: [ScriptType], memo: String?) -> Int
    func transactionSize(
        previousOutputs: [Output],
        outputScriptTypes: [ScriptType],
        memo: String?,
        pluginDataOutputSize: Int
    )
        -> Int
    func outputSize(type: ScriptType) -> Int
    func inputSize(type: ScriptType) -> Int
    func witnessSize(type: ScriptType) -> Int
    func toBytes(fee: Int) -> Int
    func transactionSize(previousOutputs: [Output], outputs: [Output]) throws -> Int
}

// MARK: - IDustCalculator

public protocol IDustCalculator {
    func dust(type: ScriptType, dustThreshold: Int?) -> Int
}

// MARK: - IUnspentOutputSelector

public protocol IUnspentOutputSelector {
    func all(filters: UtxoFilters) -> [UnspentOutput]
    func select(
        params: SendParameters,
        outputScriptType: ScriptType,
        changeType: ScriptType,
        pluginDataOutputSize: Int
    ) throws
        -> SelectedUnspentOutputInfo
}

// MARK: - IUnspentOutputProvider

public protocol IUnspentOutputProvider {
    func spendableUtxo(filters: UtxoFilters) -> [UnspentOutput]
    func confirmedSpendableUtxo(filters: UtxoFilters) -> [UnspentOutput]
}

// MARK: - IBalanceProvider

public protocol IBalanceProvider {
    var balanceInfo: BalanceInfo { get }
}

// MARK: - IBlockSyncer

public protocol IBlockSyncer: AnyObject {
    var localDownloadedBestBlockHeight: Int32 { get }
    var localKnownBestBlockHeight: Int32 { get }
    func prepareForDownload()
    func downloadStarted()
    func downloadIterationCompleted()
    func downloadCompleted()
    func downloadFailed()
    func getBlockHashes(limit: Int) -> [BlockHash]
    func getBlockLocatorHashes(peerLastBlockHeight: Int32) -> [Data]
    func add(blockHashes: [Data])
    func handle(merkleBlock: MerkleBlock, maxBlockHeight: Int32) throws
}

// MARK: - ISyncManagerDelegate

protocol ISyncManagerDelegate: AnyObject {
    func kitStateUpdated(state: BitcoinCore.KitState)
}

// MARK: - ITransactionInfo

public protocol ITransactionInfo: AnyObject {
    init(
        uid: String,
        transactionHash: String,
        transactionIndex: Int,
        inputs: [TransactionInputInfo],
        outputs: [TransactionOutputInfo],
        amount: Int,
        type: TransactionType,
        fee: Int?,
        blockHeight: Int?,
        timestamp: Int,
        status: TransactionStatus,
        conflictingHash: String?,
        rbfEnabled: Bool
    )
}

// MARK: - ITransactionInfoConverter

public protocol ITransactionInfoConverter {
    var baseTransactionInfoConverter: IBaseTransactionInfoConverter! { get set }
    func transactionInfo(fromTransaction transactionForInfo: FullTransactionForInfo) -> TransactionInfo
}

// MARK: - IDataProvider

protocol IDataProvider {
    var delegate: IDataProviderDelegate? { get set }

    var lastBlockInfo: BlockInfo? { get }
    var balance: BalanceInfo { get }
    func debugInfo(network: INetwork, scriptType: ScriptType, addressConverter: IAddressConverter) -> String
    func transactions(fromUid: String?, type: TransactionFilterType?, limit: Int?) -> [TransactionInfo]
    func transaction(hash: String) -> TransactionInfo?
    func transactionInfo(from fullInfo: FullTransactionForInfo) -> TransactionInfo
    func rawTransaction(transactionHash: String) -> String?
}

// MARK: - IDataProviderDelegate

protocol IDataProviderDelegate: AnyObject {
    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo])
    func transactionsDeleted(hashes: [String])
    func balanceUpdated(balance: BalanceInfo)
    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo)
}

// MARK: - INetwork

public protocol INetwork: AnyObject {
    var maxBlockSize: UInt32 { get }
    var protocolVersion: Int32 { get }
    var bundleName: String { get }
    var pubKeyHash: UInt8 { get }
    var privateKey: UInt8 { get }
    var scriptHash: UInt8 { get }
    var bech32PrefixPattern: String { get }
    var xPubKey: UInt32 { get }
    var xPrivKey: UInt32 { get }
    var magic: UInt32 { get }
    var port: Int { get }
    var dnsSeeds: [String] { get }
    var dustRelayTxFee: Int { get }
    var bip44Checkpoint: Checkpoint { get }
    var lastCheckpoint: Checkpoint { get }
    var coinType: UInt32 { get }
    var sigHash: SigHashType { get }
    var syncableFromApi: Bool { get }
    var blockchairChainID: String { get }
}

// MARK: - IMerkleBlockValidator

protocol IMerkleBlockValidator: AnyObject {
    func set(merkleBranch: IMerkleBranch)
    func merkleBlock(from message: MerkleBlockMessage) throws -> MerkleBlock
}

// MARK: - IMerkleBranch

public protocol IMerkleBranch: AnyObject {
    func calculateMerkleRoot(txCount: Int, hashes: [Data], flags: [UInt8]) throws
        -> (merkleRoot: Data, matchedHashes: [Data])
}

// MARK: - IMessage

public protocol IMessage {
    var description: String { get }
}

// MARK: - INetworkMessageParser

protocol INetworkMessageParser {
    func parse(data: Data) -> NetworkMessage?
}

// MARK: - IMessageParser

public protocol IMessageParser {
    var id: String { get }
    func parse(data: Data) -> IMessage
}

// MARK: - IBlockHeaderParser

protocol IBlockHeaderParser {
    func parse(byteStream: ByteStream) -> BlockHeader
}

// MARK: - INetworkMessageSerializer

protocol INetworkMessageSerializer {
    func serialize(message: IMessage) throws -> Data
}

// MARK: - IMessageSerializer

public protocol IMessageSerializer {
    var id: String { get }
    func serialize(message: IMessage) -> Data?
}

// MARK: - IInitialDownload

public protocol IInitialDownload: IPeerTaskHandler, IInventoryItemsHandler {
    var listener: IBlockSyncListener? { get set }
    var syncPeer: IPeer? { get }
    var hasSyncedPeer: Bool { get }
    var publisher: AnyPublisher<InitialDownloadEvent, Never> { get }
    var syncedPeers: [IPeer] { get }
    func isSynced(peer: IPeer) -> Bool
    func subscribeTo(publisher: AnyPublisher<PeerGroupEvent, Never>)
}

// MARK: - IInventoryItemsHandler

public protocol IInventoryItemsHandler: AnyObject {
    func handleInventoryItems(peer: IPeer, inventoryItems: [InventoryItem])
}

// MARK: - IPeerTaskHandler

public protocol IPeerTaskHandler: AnyObject {
    func handleCompletedTask(peer: IPeer, task: PeerTask) -> Bool
}

// MARK: - ITransactionSender

protocol ITransactionSender {
    func verifyCanSend() throws
    func send(pendingTransaction: FullTransaction)
    func transactionsRelayed(transactions: [FullTransaction])
}

// MARK: - ITransactionSendTimerDelegate

protocol ITransactionSendTimerDelegate: AnyObject {
    func timePassed()
}

// MARK: - ITransactionSendTimer

protocol ITransactionSendTimer {
    var delegate: ITransactionSendTimerDelegate? { get set }
    func startIfNotRunning()
    func stop()
}

// MARK: - IMerkleBlockHandler

protocol IMerkleBlockHandler: AnyObject {
    func handle(merkleBlock: MerkleBlock) throws
}

// MARK: - ITransactionListener

// protocol ITransactionHandler: AnyObject {
//    func handle(transaction: FullTransaction, transactionHash: TransactionHash) throws
// }

protocol ITransactionListener: AnyObject {
    func onReceive(transaction: FullTransaction)
}

// MARK: - IWatchedTransactionDelegate

public protocol IWatchedTransactionDelegate {
    func transactionReceived(transaction: FullTransaction, outputIndex: Int)
    func transactionReceived(transaction: FullTransaction, inputIndex: Int)
}

// MARK: - IWatchedTransactionManager

protocol IWatchedTransactionManager {
    func add(transactionFilter: BitcoinCore.TransactionFilter, delegatedTo: IWatchedTransactionDelegate)
}

// MARK: - IBloomFilterProvider

protocol IBloomFilterProvider: AnyObject {
    var bloomFilterManager: IBloomFilterManager? { set get }
    func filterElements() -> [Data]
}

// MARK: - IIrregularOutputFinder

protocol IIrregularOutputFinder {
    func hasIrregularOutput(outputs: [Output]) -> Bool
}

// MARK: - IPlugin

public protocol IPlugin: IRestoreKeyConverter {
    var id: UInt8 { get }
    var maxSpendLimit: Int? { get }
    func validate(address: Address) throws
    func processOutputs(mutableTransaction: MutableTransaction, pluginData: IPluginData, skipChecks: Bool) throws
    func processTransactionWithNullData(
        transaction: FullTransaction,
        nullDataChunks: inout IndexingIterator<[Chunk]>
    ) throws
    func isSpendable(unspentOutput: UnspentOutput) throws -> Bool
    func inputSequenceNumber(output: Output) throws -> Int
    func parsePluginData(from: String, transactionTimestamp: Int) throws -> IPluginOutputData
    func incrementSequence(sequence: Int) -> Int
}

extension IPlugin {
    public func bloomFilterElements(publicKey _: PublicKey) -> [Data] { [] }
}

// MARK: - IPluginManager

public protocol IPluginManager {
    func validate(address: Address, pluginData: [UInt8: IPluginData]) throws
    func maxSpendLimit(pluginData: [UInt8: IPluginData]) throws -> Int?
    func add(plugin: IPlugin)
    func processOutputs(
        mutableTransaction: MutableTransaction,
        pluginData: [UInt8: IPluginData],
        skipChecks: Bool
    ) throws
    func processInputs(mutableTransaction: MutableTransaction) throws
    func processTransactionWithNullData(transaction: FullTransaction, nullDataOutput: Output) throws
    func isSpendable(unspentOutput: UnspentOutput) -> Bool
    func parsePluginData(fromPlugin: UInt8, pluginDataString: String, transactionTimestamp: Int) -> IPluginOutputData?
    func incrementedSequence(of: InputWithPreviousOutput) -> Int
}

// MARK: - IBlockMedianTimeHelper

public protocol IBlockMedianTimeHelper {
    var medianTimePast: Int? { get }
    func medianTimePast(block: Block) -> Int?
}

// MARK: - IRecipientSetter

protocol IRecipientSetter {
    func setRecipient(to mutableTransaction: MutableTransaction, params: SendParameters, skipChecks: Bool) throws
}

// MARK: - IOutputSetter

protocol IOutputSetter {
    func setOutputs(to mutableTransaction: MutableTransaction, sortType: TransactionDataSortType)
}

// MARK: - IInputSetter

protocol IInputSetter {
    @discardableResult
    func setInputs(to mutableTransaction: MutableTransaction, params: SendParameters) throws -> InputSetter
        .OutputInfo
    func setInputs(
        to mutableTransaction: MutableTransaction,
        fromUnspentOutput unspentOutput: UnspentOutput,
        params: SendParameters
    ) throws
}

// MARK: - ILockTimeSetter

protocol ILockTimeSetter {
    func setLockTime(to mutableTransaction: MutableTransaction)
}

// MARK: - ITransactionSigner

protocol ITransactionSigner {
    func sign(mutableTransaction: MutableTransaction) throws
}

// MARK: - IPluginData

public protocol IPluginData { }

// MARK: - IPluginOutputData

public protocol IPluginOutputData { }

// MARK: - ITransactionDataSorterFactory

protocol ITransactionDataSorterFactory {
    func sorter(for type: TransactionDataSortType) -> ITransactionDataSorter
}

// MARK: - ITransactionDataSorter

protocol ITransactionDataSorter {
    func sort(outputs: [Output]) -> [Output]
    func sort(unspentOutputs: [UnspentOutput]) -> [UnspentOutput]
}
