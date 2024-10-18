//
//  BitcoinPaymentData.swift
//  BitcoinCore
//
//  Created by Sun on 2018/11/30.
//

import Foundation

public struct BitcoinPaymentData: Equatable {
    // MARK: Properties

    public let address: String

    public let version: String?
    public let amount: Double?
    public let label: String?
    public let message: String?

    public let parameters: [String: String]?

    // MARK: Computed Properties

    var uriPaymentAddress: String {
        var uriAddress = address
        if let version {
            uriAddress.append(";version=" + version)
        }
        if let amount {
            uriAddress.append("?amount=\(amount)")
        }
        if let label {
            uriAddress.append("?label=" + label)
        }
        if let message {
            uriAddress.append("?message=" + message)
        }
        if let parameters {
            for (name, value) in parameters {
                uriAddress.append("?\(name)=" + value)
            }
        }

        return uriAddress
    }

    // MARK: Lifecycle

    init(
        address: String,
        version: String? = nil,
        amount: Double? = nil,
        label: String? = nil,
        message: String? = nil,
        parameters: [String: String]? = nil
    ) {
        self.address = address
        self.version = version
        self.amount = amount
        self.label = label
        self.message = message
        self.parameters = parameters
    }

    // MARK: Static Functions

    public static func == (lhs: BitcoinPaymentData, rhs: BitcoinPaymentData) -> Bool {
        lhs.address == rhs.address &&
            lhs.version == rhs.version &&
            lhs.amount == rhs.amount &&
            lhs.label == rhs.label &&
            lhs.message == rhs.message &&
            lhs.parameters == rhs.parameters
    }
}
