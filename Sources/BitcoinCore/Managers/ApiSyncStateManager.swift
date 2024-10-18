//
//  ApiSyncStateManager.swift
//  BitcoinCore
//
//  Created by Sun on 2018/8/23.
//

import Foundation

// MARK: - ApiSyncStateManager

public class ApiSyncStateManager {
    // MARK: Properties

    private let storage: IStorage
    private let restoreFromApi: Bool

    // MARK: Lifecycle

    public init(storage: IStorage, restoreFromApi: Bool) {
        self.storage = storage
        self.restoreFromApi = restoreFromApi
    }
}

// MARK: IApiSyncStateManager

extension ApiSyncStateManager: IApiSyncStateManager {
    var restored: Bool {
        get {
            guard restoreFromApi else {
                return true
            }

            return storage.initialRestored ?? false
        }
        set {
            storage.set(initialRestored: newValue)
        }
    }
}
