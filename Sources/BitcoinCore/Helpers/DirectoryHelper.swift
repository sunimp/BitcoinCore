//
//  DirectoryHelper.swift
//  BitcoinCore
//
//  Created by Sun on 2019/5/8.
//

import Foundation

public enum DirectoryHelper {
    public static func directoryURL(for directoryName: String) throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(directoryName, isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    public static func removeDirectory(_ name: String) throws {
        try FileManager.default.removeItem(at: directoryURL(for: name))
    }

    public static func removeAll(inDirectory directoryName: String, except excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileURLs = try fileManager.contentsOfDirectory(
            at: directoryURL(for: directoryName),
            includingPropertiesForKeys: nil
        )

        for filename in fileURLs {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }
}
