//
//  SystemUtility+AppleScript.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/2.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

/// Frontmost application bundle identifier
var frontmostAppBundleID: String {
    NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
}
