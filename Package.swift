// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "BitcoinCore",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "BitcoinCore",
            targets: ["BitcoinCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.4.1"),
        .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "6.29.3")),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.6.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.6.2"),
        .package(url: "https://github.com/sunimp/Checkpoints.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/sunimp/HDWalletKit.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/sunimp/SWCryptoKit.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/sunimp/SWExtensions.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/sunimp/SWToolKit.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.6"),
    ],
    targets: [
        .target(
            name: "BitcoinCore",
            dependencies: [
                "BigInt",
                "Checkpoints",
                "HDWalletKit",
                "SWCryptoKit",
                "SWExtensions",
                "SWToolKit",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "BitcoinCoreTests",
            dependencies: [
                "BitcoinCore",
                "Nimble",
                "Quick",
            ]
        ),
    ]
)
