//
//  AddressConverterChain.swift
//  BitcoinCore
//
//  Created by Sun on 2019/4/3.
//

import Foundation

public class AddressConverterChain: IAddressConverter {
    // MARK: Properties

    private var concreteConverters = [IAddressConverter]()

    // MARK: Lifecycle

    public init() { }

    // MARK: Functions

    public func prepend(addressConverter: IAddressConverter) {
        concreteConverters.insert(addressConverter, at: 0)
    }

    public func convert(address: String) throws -> Address {
        var errors = [Error]()

        for converter in concreteConverters {
            do {
                return try converter.convert(address: address)
            } catch {
                errors.append(error)
            }
        }

        throw BitcoinCoreErrors.AddressConversionErrors(errors: errors)
    }

    public func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address {
        var errors = [Error]()

        for converter in concreteConverters {
            do {
                return try converter.convert(lockingScriptPayload: lockingScriptPayload, type: type)
            } catch {
                errors.append(error)
            }
        }

        throw BitcoinCoreErrors.AddressConversionErrors(errors: errors)
    }

    public func convert(publicKey: PublicKey, type: ScriptType) throws -> Address {
        var errors = [Error]()

        for converter in concreteConverters {
            do {
                return try converter.convert(publicKey: publicKey, type: type)
            } catch {
                errors.append(error)
            }
        }

        throw BitcoinCoreErrors.AddressConversionErrors(errors: errors)
    }
}
