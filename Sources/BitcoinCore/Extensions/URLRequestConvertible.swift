//
//  URLRequestConvertible.swift
//  BitcoinCore
//
//  Created by Sun on 2019/11/7.
//

import Foundation

import Alamofire

extension URLRequestConvertible {
    var description: String {
        "\(urlRequest?.httpMethod ?? "") \(urlRequest?.url?.absoluteString ?? "")"
    }
}
