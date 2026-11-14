//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SelectedTextKit

// MARK: - SystemUtility

@objc(EZSystemUtility)
class SystemUtility: NSObject {
    @objc static let shared = SystemUtility()

    let axManager = AXManager.shared
    let pasteboardManager = PasteboardManager.shared
    let selectedTextManager = SelectedTextManager.shared

    /// Bundle identifiers of apps that should use the "Paste menu item enabled" heuristic
    /// when the focused text field element cannot be reliably determined via Accessibility APIs.
    var bundleIDAllowListForPasteMenuCheck: Set<String> = [AppBundleIDs.weChat]

    /// Bundle identifiers of apps allowed to bypass focused element checks for selectable text.
    /// Useful when focused UI element cannot be reliably determined via Accessibility APIs,
    /// e.g. Sublime Text's focused element role is AXWindow, but its selection can still be
    /// obtained by force-get (simulated copy).
    var bundleIDAllowListForSelectableTextCheck: Set<String> = [
        AppBundleIDs.weChat,
        AppBundleIDs.sublimeText,
        AppBundleIDs.zenBrowser,
    ]

    /// Get selected text from current focused application.
    ///
    /// - Note: Just a wrapper of EZEventMonitor's getSelectedText method.
    func getSelectedText() async -> String? {
        await EventMonitor.shared.getSelectedText()
    }
}
