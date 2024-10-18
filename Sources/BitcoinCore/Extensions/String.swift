//
//  String.swift
//  BitcoinCore
//
//  Created by Sun on 2018/7/18.
//

import Foundation

import SWExtensions

extension String {
    public var reversedData: Data? {
        self.sw.hexData.map { Data($0.reversed()) }
    }
}
