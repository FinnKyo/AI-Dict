//
//  AppPathManager+Cache.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
    /// The root directory for app-managed disposable data.
    var cacheDirectory: URL {
        appSupportDirectory.appendingPathComponent("cache", isDirectory: true)
    }
}
