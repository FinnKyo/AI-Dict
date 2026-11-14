//
//  QueryResult.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/20.
//  Copyright © 2025 izual. All rights reserved.
//

import CoreGraphics
import Defaults
import Foundation

// MARK: - QueryResult

/// Stores the translation or dictionary results for a query.
@objcMembers
@objc(EZQueryResult)
public class QueryResult: NSObject {
    // MARK: Lifecycle

    /// Creates a new query result with default values.
    override init() {
        super.init()
        reset()
    }

    // MARK: Internal

    var queryModel: QueryModel = .init()

    var serviceTypeWithUniqueIdentifier: String = ServiceType.openRouter.rawValue

    var isShowing: Bool = false
    var viewHeight: CGFloat = 0

    var isLoading: Bool = false
    var isStreamFinished: Bool = true

    var queryText: String = ""
    var from: Language = .auto
    var to: Language = .auto

    var error: QueryError?

    var manualShow: Bool = false

    @nonobjc var raw: Any?

    var promptTitle: String?
    var promptURL: String?

    /// Optional message set during validation to provide extra context (e.g. streaming auto-disabled).
    var validationMessage: String?

    /// Per-result override for Markdown rendering. `nil` defers to the global
    /// `Defaults[.enableMarkdownRendering]` value; a non-nil value reflects an
    /// explicit toggle on the inline button next to this card. Reset on each
    /// new query so a fresh result tracks the global setting again.
    var markdownRenderingOverride: Bool?

    var translatedResults: [String]? {
        get {
            translatedResultsLock.lock()
            defer { translatedResultsLock.unlock() }
            return translatedResultsStorage
        }
        set {
            translatedResultsLock.lock()
            translatedResultsStorage = newValue
            translatedResultsLock.unlock()
        }
    }

    var translatedText: String? {
        guard let translatedResults else { return nil }
        return translatedResults.joined(separator: "\n")
    }

    /// Effective Markdown rendering decision for this result. The per-result
    /// override (set via the inline toggle button) wins; otherwise the global
    /// `Defaults[.enableMarkdownRendering]` value is used.
    var isMarkdownRenderingEnabled: Bool {
        markdownRenderingOverride ?? Defaults[.enableMarkdownRendering]
    }

    var hasShowingResult: Bool {
        hasTranslatedResult || error != nil
    }

    var hasTranslatedResult: Bool {
        translatedText != nil
    }

    var isWarningErrorType: Bool {
        guard let error else { return false }
        return error.type == .unsupportedLanguage || error.type == .noResult
    }

    var copiedText: String? {
        translatedText
    }

    var queryFromLanguage: Language {
        queryModel.queryFromLanguage
    }

    var errorMessage: String? {
        error?.localizedDescription
    }

    /// Flips the Markdown rendering decision for this result, overriding the
    /// global setting until the result is reset by a new query.
    func toggleMarkdownRendering() {
        markdownRenderingOverride = !isMarkdownRenderingEnabled
    }

    /// Resets the result to its initial state.
    func reset() {
        queryModel = QueryModel()
        translatedResults = nil
        error = nil
        validationMessage = nil
        serviceTypeWithUniqueIdentifier = ServiceType.openRouter.rawValue
        isShowing = false
        isLoading = false
        viewHeight = 0
        queryText = ""
        from = .auto
        to = .auto
        raw = nil
        promptTitle = nil
        promptURL = nil
        isStreamFinished = true
        manualShow = false
        markdownRenderingOverride = nil
    }

    /// Converts translated results to Traditional Chinese.
    func convertToTraditionalChineseResult() {
        translatedResults = translatedResults?.toTraditionalChineseTexts()
    }

    // MARK: Private

    private let translatedResultsLock = NSLock()
    private var translatedResultsStorage: [String]?
}
