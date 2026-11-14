//
//  AppleScriptTask+Browser.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/11.
//  Copyright © 2024 izual. All rights reserved.
//

extension AppleScriptTask {
    // MARK: Internal

    /// Browser action types for better abstraction
    enum BrowserAction {
        case getCurrentTabURL
        case getSelectedText
    }

    class func isBrowserSupportingAppleScript(_ bundleID: String) -> Bool {
        browsersSupportingAppleScript.contains(bundleID)
    }

    class func isSafari(_ bundleID: String) -> Bool {
        bundleID == AppBundleIDs.safari
    }

    class func isChromeKernelBrowser(_ bundleID: String) -> Bool {
        chromeKernelBrowsers.contains(bundleID)
    }

    class func getSelectedTextFromBrowser(_ bundleID: String) async throws -> String? {
        try await executeBrowserAction(.getSelectedText, bundleID: bundleID)
    }

    class func getCurrentTabURLFromBrowser(_ bundleID: String) async throws -> String? {
        try await executeBrowserAction(.getCurrentTabURL, bundleID: bundleID)
    }

    // MARK: Private

    /// Generic browser action executor that handles Safari and Chrome differences
    private class func executeBrowserAction(_ action: BrowserAction, bundleID: String) async throws
        -> String? {
        guard isBrowserSupportingAppleScript(bundleID) else { return nil }

        let script: String
        let timeout: TimeInterval?
        let logMessage: String

        if isSafari(bundleID) {
            (script, timeout, logMessage) = safariScriptFor(action: action, bundleID: bundleID)
        } else if isChromeKernelBrowser(bundleID) {
            (script, timeout, logMessage) = chromeScriptFor(action: action, bundleID: bundleID)
        } else {
            return nil
        }

        let result = try await runAppleScript(script, timeout: timeout ?? 5.0)
        logInfo("\(logMessage): \(result ?? "")")
        return result
    }

    // MARK: - Chrome AppleScript

    /// Generate Chrome-specific AppleScript for different actions
    private class func chromeScriptFor(action: BrowserAction, bundleID: String) -> (
        script: String, timeout: TimeInterval?, logMessage: String
    ) {
        switch action {
        case .getCurrentTabURL:
            let script = """
            tell application id "\(bundleID)"
               set theUrl to URL of active tab of front window
            end tell
            """
            return (script, nil, "Chrome current tab URL")

        case .getSelectedText:
            let script = """
            tell application id "\(bundleID)"
               tell active tab of front window
                   set selection_text to execute javascript "window.getSelection().toString();"
               end tell
            end tell
            """
            return (script, 0.2, "Chrome Browser selected text")
        }
    }

    // MARK: - Safari AppleScript

    /// Generate Safari-specific AppleScript for different actions
    private class func safariScriptFor(action: BrowserAction, bundleID: String) -> (
        script: String, timeout: TimeInterval?, logMessage: String
    ) {
        switch action {
        case .getCurrentTabURL:
            let script = """
            tell application id "\(bundleID)"
               set theUrl to URL of front document
            end tell
            """
            return (script, nil, "Safari current tab URL")

        case .getSelectedText:
            let script = """
            tell application id "\(bundleID)"
                tell front window
                    set selection_text to do JavaScript "window.getSelection().toString();" in current tab
                end tell
            end tell
            """
            return (script, 0.2, "Safari selected text")
        }
    }

    /// Modern implementation for selecting all text in the focused element
    /// Escape JavaScript string to prevent injection and handle special characters.
    /// The JavaScript code is inside AppleScript's double-quoted string, and JS string uses single quotes.
    /// AppleScript requires backslash to be escaped as \\, and for JS single quote we need \'
    /// So in AppleScript double-quoted string: \\\' represents a literal \' which JS interprets as escaped quote
    ///
    /// - Example:
    ///   - Original string: `\` This is a special character.\n" test"\n"\\" Hello.
    ///   - After escaping: `\\\\` This is a special character.\\n\"test\"\\n\"\\\\\\\\\" Hello.
    // MARK: - Static Data

    private static let chromeKernelBrowsers = [
        AppBundleIDs.googleChrome,
        AppBundleIDs.microsoftEdge,
    ]

    static let browsersSupportingAppleScript = [
        AppBundleIDs.safari,
        AppBundleIDs.googleChrome,
        AppBundleIDs.microsoftEdge,
    ]
}
