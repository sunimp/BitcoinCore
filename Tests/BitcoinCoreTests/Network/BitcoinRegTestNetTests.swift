//
//  BitcoinRegTestNetTests.swift
//  BitcoinCore
//
//  Created by Sun on 2018/9/20.
//

// import XCTest
// import Cuckoo
// @testable import BitcoinCore
//
// class BitcoinRegTestNetTests:XCTestCase {
//
//    private var mockNetwork: BitcoinMainNet!
//    private var mockValidatorHelper: MockValidatorHelper!
//    private var mockMerkleBranch: MockIMerkleBranch!
//
//    override func setUp() {
//        super.setUp()
//
//        mockValidatorHelper = MockValidatorHelper()
//        mockMerkleBranch = MockIMerkleBranch()
//        mockNetwork = BitcoinMainNet(validatorFactory: mockValidatorHelper.mockFactory, merkleBranch:
//        mockMerkleBranch)
//    }
//
//    override func tearDown() {
//        mockNetwork = nil
//        mockValidatorHelper = nil
//
//        super.tearDown()
//    }
//
//    func testValidate() {
//        let block = TestData.firstBlock
//        do {
//            try mockNetwork.validate(block: block, previousBlock: TestData.checkpointBlock)
//            verify(mockValidatorHelper.mockHeaderValidator, times(1)).validate(candidate: any(), block: any(),
//            network: any())
//        } catch let error {
//            XCTFail("\(error) Exception Thrown")
//        }
//    }
//
// }
