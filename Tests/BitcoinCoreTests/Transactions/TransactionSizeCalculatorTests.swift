//
//  TransactionSizeCalculatorTests.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/27.
//

@testable import BitcoinCore
import XCTest

class TransactionSizeCalculatorTests: XCTestCase {
    // MARK: Properties

    var calculator: TransactionSizeCalculator!

    // MARK: Overridden Functions

    override func setUp() {
        super.setUp()

        calculator = TransactionSizeCalculator()
    }

    override func tearDown() {
        calculator = nil

        super.tearDown()
    }

    // MARK: Functions

    func testTransactionSize() {
        XCTAssertEqual(
            calculator.transactionSize(previousOutputs: [], outputScriptTypes: [], memo: nil),
            10
        ) // empty legacy tx
        XCTAssertEqual(
            calculator
                .transactionSize(
                    previousOutputs: outputs(withScriptTypes: [.p2pkh]),
                    outputScriptTypes: [.p2pkh],
                    memo: nil
                ),
            192
        ) // 1-in 1-out standard tx
        XCTAssertEqual(
            calculator
                .transactionSize(
                    previousOutputs: outputs(withScriptTypes: [.p2pkh, .p2pk]),
                    outputScriptTypes: [.p2pkh],
                    memo: nil
                ),
            306
        ) // 2-in 1-out legacy tx
        XCTAssertEqual(
            calculator
                .transactionSize(
                    previousOutputs: outputs(withScriptTypes: [.p2pkh, .p2pk]),
                    outputScriptTypes: [.p2wpkh],
                    memo: nil
                ),
            303
        ) // 2-in 1-out legacy tx with witness output
        XCTAssertEqual(
            calculator.transactionSize(previousOutputs: outputs(withScriptTypes: [.p2pkh, .p2pk]), outputScriptTypes: [
                .p2pkh,
                .p2pk,
            ], memo: nil),
            350
        ) // 2-in 2-out legacy tx

        XCTAssertEqual(
            calculator
                .transactionSize(
                    previousOutputs: outputs(withScriptTypes: [.p2wpkh]),
                    outputScriptTypes: [.p2pkh],
                    memo: nil
                ),
            113
        ) // 1-in 1-out witness tx
        XCTAssertEqual(
            calculator
                .transactionSize(
                    previousOutputs: outputs(withScriptTypes: [.p2wpkhSh]),
                    outputScriptTypes: [.p2pkh],
                    memo: nil
                ),
            136
        ) // 1-in 1-out (sh) witness tx
        XCTAssertEqual(
            calculator
                .transactionSize(
                    previousOutputs: outputs(withScriptTypes: [.p2wpkh, .p2pkh, .p2pkh, .p2pkh]),
                    outputScriptTypes: [.p2pkh],
                    memo: nil
                ),
            558
        ) // 4-in 1-out witness tx
    }

    func testTransactionSizeShInputsStandard() {
        let redeemScript = Data(repeating: 0, count: 45)
        let shOutput = Output(withValue: 0, index: 0, lockingScript: Data(), type: .p2sh, redeemScript: redeemScript)

        XCTAssertEqual(
            calculator.transactionSize(previousOutputs: [shOutput], outputScriptTypes: [.p2pkh], memo: nil),
            238
        )
    }

    func testTransactionSizeShInputsNonStandard() {
        let shOutput = Output(withValue: 0, index: 0, lockingScript: Data(), type: .p2sh, redeemScript: Data())
        shOutput.signatureScriptFunction = { _ in
            Data(repeating: 0, count: 100)
        }

        XCTAssertEqual(
            calculator.transactionSize(previousOutputs: [shOutput], outputScriptTypes: [.p2pkh], memo: nil),
            185
        )
    }

    func testInputSize() {
        XCTAssertEqual(calculator.inputSize(type: .p2pkh), 148)
        XCTAssertEqual(calculator.inputSize(type: .p2pk), 114)
        XCTAssertEqual(calculator.inputSize(type: .p2wpkh), 41)
        XCTAssertEqual(calculator.inputSize(type: .p2wpkhSh), 64)
    }

    func testOutputSize() {
        XCTAssertEqual(calculator.outputSize(type: .p2pkh), 34)
        XCTAssertEqual(calculator.outputSize(type: .p2sh), 32)
        XCTAssertEqual(calculator.outputSize(type: .p2pk), 44)
        XCTAssertEqual(calculator.outputSize(type: .p2wpkh), 31)
        XCTAssertEqual(calculator.outputSize(type: .p2wpkhSh), 32)
    }
}
