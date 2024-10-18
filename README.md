# BitcoinCore

`BitcoinCore` is a core package that implements a full Simplified Payment Verification (`SPV`) client in `Swift`. It implements Bitcoin `P2P Protocol` and can be extended to be a client of other Bitcoin forks.

## Requirements

* Xcode 15.4+
* Swift 5.10+
* iOS 14.0+

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/sunimp/BitcoinCore.git", .upToNextMajor(from: "1.0.0"))
]
```

## License

The `BitcoinCore` toolkit is open source and available under the terms of the [MIT License](https://github.com/sunimp/BitcoinCore/blob/master/LICENSE).
