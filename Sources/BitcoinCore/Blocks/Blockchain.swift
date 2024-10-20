//
//  Blockchain.swift
//  BitcoinCore
//
//  Created by Sun on 2018/10/17.
//

import Foundation

import SWExtensions

// MARK: - Blockchain

class Blockchain {
    // MARK: Properties

    weak var listener: IBlockchainDataListener?

    private let storage: IStorage
    private var blockValidator: IBlockValidator?
    private let factory: IFactory
    private var previousBlock: Block?

    // MARK: Lifecycle

    init(
        storage: IStorage,
        blockValidator: IBlockValidator?,
        factory: IFactory,
        listener: IBlockchainDataListener? = nil
    ) {
        self.storage = storage
        self.blockValidator = blockValidator
        self.factory = factory
        self.listener = listener
    }
}

// MARK: IBlockchain

extension Blockchain: IBlockchain {
    func connect(merkleBlock: MerkleBlock) throws -> Block {
        if let existingBlock = storage.block(byHash: merkleBlock.headerHash) {
            return existingBlock
        }

        guard
            let previousBlock = previousBlock ?? storage.block(byHash: merkleBlock.header.previousBlockHeaderHash),
            previousBlock.headerHash == merkleBlock.header.previousBlockHeaderHash
        else {
            throw BitcoinCoreErrors.BlockValidation.noPreviousBlock
        }

        // Validate and chain new blocks
        let block = factory.block(withHeader: merkleBlock.header, previousBlock: previousBlock)
        try blockValidator?.validate(block: block, previousBlock: previousBlock)
        block.stale = true

        try storage.add(block: block)
        listener?.onInsert(block: block)

        if block.height % 2016 == 0 {
            storage.deleteUselessBlocks(before: block.height - 2016)
            storage.releaseMemory()
        }

        return block
    }

    func forceAdd(merkleBlock: MerkleBlock, height: Int) throws -> Block {
        if let existingBlock = storage.block(byHash: merkleBlock.headerHash) {
            return existingBlock
        }

        let block = factory.block(withHeader: merkleBlock.header, height: height)
        try storage.add(block: block)

        listener?.onInsert(block: block)

        return block
    }

    func insertLastBlock(header: BlockHeader, height: Int) throws {
        guard storage.block(byHash: header.headerHash) == nil else {
            return
        }

        let block = factory.block(withHeader: header, height: height)
        try storage.add(block: block)

        listener?.onInsert(block: block)
    }

    func handleFork() throws {
        guard let firstStaleHeight = storage.block(stale: true, sortedHeight: "ASC")?.height else {
            return
        }

        let lastNotStaleHeight = storage.block(stale: false, sortedHeight: "DESC")?.height ?? 0

        if firstStaleHeight <= lastNotStaleHeight {
            let lastStaleHeight = storage.block(stale: true, sortedHeight: "DESC")?.height ?? firstStaleHeight

            if lastStaleHeight > lastNotStaleHeight {
                let notStaleBlocks = storage.blocks(heightGreaterThanOrEqualTo: firstStaleHeight, stale: false)
                try deleteBlocks(blocks: notStaleBlocks)
                try storage.unstaleAllBlocks()
            } else {
                let staleBlocks = storage.blocks(stale: true)
                try deleteBlocks(blocks: staleBlocks)
            }
        } else {
            try storage.unstaleAllBlocks()
        }
    }

    func deleteBlocks(blocks: [Block]) throws {
        let hashes = blocks.reduce(into: [String]()) { acc, block in
            acc.append(contentsOf: storage.transactions(ofBlock: block).map(\.dataHash.sw.reversedHex))
        }

        try storage.delete(blocks: blocks)
        listener?.onDelete(transactionHashes: hashes)
    }
}
