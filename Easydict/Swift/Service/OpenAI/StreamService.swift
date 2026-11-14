//
//  StreamService.swift
//  Easydict
//
//  Created by tisfeng on 2024/5/20.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import AppKit
import Combine
import Defaults
import Foundation
import OpenAI
import SwiftUI

// MARK: - StreamService

@objcMembers
@objc(EZStreamService)
public class StreamService: QueryService {
    // MARK: Lifecycle

    required init() {
        super.init()

        // Since getter Defaults[key] cost CPU high when update too frequently, we observe it here.

        Defaults.publisher(thinkTagKey)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.hideThinkTagContent = $0.newValue
            }
            .store(in: &cancellables)
    }

    // MARK: Open

    /// Cancels the current streaming request manually.
    open override func cancelStream() {}

    // MARK: Public

    /// Whether the service should be treated as stream-capable by higher layers.
    ///
    /// This describes service capability, not the concrete transport of the current request.
    /// UI code uses this semantic to decide behaviors such as showing the stop button and
    /// delaying auto-copy until the stream finishes.
    public override func isStream() -> Bool {
        true
    }

    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let allLanguages = EZLanguageManager.shared().allLanguages
        let supportedLanguages = allLanguages.filter { language in
            !unsupportedLanguages.contains(language)
        }
        return supportedLanguages.toMMOrderedDictionary()
    }

    public override func supportedQueryType() -> EZQueryTextType {
        [.translation, .dictionary]
    }

    public override func serviceUsageStatus() -> EZServiceUsageStatus {
        Defaults[serviceUsageStatusKey].ezStatus
    }

    /// Translate text and return the final streaming result.
    @nonobjc
    public override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        let generation = updateResultLock.withLock { resultGeneration }
        var latestResult = result ?? QueryResult()
        do {
            for try await result in translateStream(text, from: from, to: to) {
                latestResult = result
            }
        } catch {
            try updateResultLock.withLock {
                guard resultGeneration == generation else { throw CancellationError() }
                latestResult = result ?? latestResult
                if latestResult.error == nil {
                    latestResult.error = QueryError.queryError(from: error)
                }
            }
            throw error
        }
        return try updateResultLock.withLock {
            guard resultGeneration == generation else { throw CancellationError() }
            return latestResult
        }
    }

    /// Translate text and return a throttled stream of results.
    @nonobjc
    public override func translateStream(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<QueryResult, Error> {
        let (activeResult, activeGeneration) = updateResultLock.withLock {
            let activeResult = result ?? QueryResult()
            if result == nil { result = activeResult }
            return (activeResult, resultGeneration)
        }
        let queryResultStream = streamTranslate(
            text: text,
            from: from,
            to: to,
            targetResult: activeResult,
            targetGeneration: activeGeneration
        )
        let textStream = queryResultStreamToTextStream(queryResultStream)

        return AsyncThrowingStream { [weak self] continuation in
            let task = Task {
                guard let self else {
                    continuation.finish()
                    return
                }

                var didYieldError = false

                do {
                    try await self.throttleUpdateResultText(
                        textStream,
                        queryType: self.supportedQueryType(),
                        error: nil,
                        targetResult: activeResult,
                        targetGeneration: activeGeneration
                    ) { result in
                        if result.error != nil {
                            didYieldError = true
                        }
                        continuation.yield(result)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    self.updateResultLock.withLock {
                        guard self.resultGeneration == activeGeneration else { return }
                        activeResult.isStreamFinished = true
                        activeResult.isLoading = false
                        activeResult.error = nil
                        continuation.yield(activeResult)
                    }
                    continuation.finish()
                } catch {
                    self.updateResultLock.withLock {
                        guard self.resultGeneration == activeGeneration else {
                            continuation.finish()
                            return
                        }
                        if !didYieldError {
                            if activeResult.error == nil {
                                activeResult.error = QueryError.queryError(from: error)
                            }
                            continuation.yield(activeResult)
                        }
                        continuation.finish(throwing: error)
                    }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .userProvided
    }

    public override func hasPrivateAPIKey() -> Bool {
        !apiKey.isEmpty
    }

    // MARK: Internal

    let mustOverride = "This property or method must be overridden by a subclass"

    var cancellables: Set<AnyCancellable> = []

    var hideThinkTagContent: Bool = true

    /// The optional OpenAI-compatible reasoning mode for stream services.
    /// Subclasses can override this when the selected provider supports the parameter.
    @nonobjc
    var reasoningEffort: ChatQuery.ReasoningEffort? {
        nil
    }

    /// Whether requests currently use streaming transport over the network.
    ///
    /// This is intentionally narrower than `isStream()`: a service may remain stream-capable
    /// while temporarily using a non-streaming transport, such as Custom OpenAI fallback mode.
    var usesStreamingTransport: Bool {
        enableStreaming
    }

    /// Whether model changes should remain synchronized with the supported-model list.
    ///
    /// Services with free-form model input can disable this to prevent delayed
    /// configuration callbacks from rewriting the user's latest model value.
    var synchronizesModelWithSupportedModels: Bool {
        true
    }

    var model: String {
        get {
            var model = Defaults[modelKey]
            let currentValidModels = validModels
            if !currentValidModels.contains(model) || model.isEmpty {
                model = currentValidModels.first ?? ""
                Defaults[modelKey] = model
            }
            return model
        }
        set {
            Defaults[modelKey] = newValue
        }
    }

    var defaultModels: [String] {
        [""]
    }

    var defaultModel: String {
        defaultModels.first ?? ""
    }

    /// Query-window presentation is separate from the ID passed to the provider.
    @MainActor var modelDisplayName: String { model }

    @MainActor var selectableModels: [String] { validModels }

    var unsupportedLanguages: [Language] {
        []
    }

    var modelKey: Defaults.Key<String> {
        stringDefaultsKey(.model, defaultValue: defaultModel)
    }

    /// When `supportedModels` is set, `validModels` will be updated automatically.
    var supportedModels: String {
        get { Defaults[supportedModelsKey] }
        set {
            Defaults[supportedModelsKey] = newValue
            Defaults[validModelsKey] = validModels(from: newValue)
        }
    }

    var supportedModelsKey: Defaults.Key<String> {
        stringDefaultsKey(.supportedModels, defaultValue: supportedModels(from: defaultModels))
    }

    /// Just getter, we should not change it directly, we should set `supportedModels` instead.
    var validModels: [String] {
        Defaults[validModelsKey]
    }

    var validModelsKey: Defaults.Key<[String]> {
        serviceDefaultsKey(.validModels, defaultValue: defaultModels)
    }

    var apiKey: String {
        Defaults[apiKeyKey]
    }

    var apiKeyKey: Defaults.Key<String> {
        stringDefaultsKey(.apiKey)
    }

    var endpoint: String {
        let configuredEndpoint = Defaults[endpointKey]
        return configuredEndpoint.isEmpty ? defaultEndpoint : configuredEndpoint
    }

    var endpointKey: Defaults.Key<String> {
        stringDefaultsKey(.endpoint, defaultValue: defaultEndpoint)
    }

    var endpointPlaceholder: String {
        defaultEndpoint
            .isEmpty
            ? String(localized: "service.configuration.openai.endpoint.placeholder")
            : defaultEndpoint
    }

    var defaultEndpoint: String {
        ""
    }

    var nameKey: Defaults.Key<String> {
        stringDefaultsKey(.name)
    }

    var serviceUsageStatusKey: Defaults.Key<ServiceUsageStatus> {
        serviceDefaultsKey(.serviceUsageStatus, defaultValue: .default)
    }

    var thinkTagKey: Defaults.Key<Bool> {
        boolDefaultsKey(.thinkTag, defaultValue: true)
    }

    // In general, LLM services need to observe these keys to enable validation button.
    var observeKeys: [Defaults.Key<String>] {
        [
            apiKeyKey,
            endpointKey,
            supportedModelsKey,
        ]
    }

    var apiKeyPlaceholder: String {
        String(localized: "service.configuration.api_key.placeholder \(serviceType().rawValue)")
    }

    var enableStreamingKey: Defaults.Key<Bool> {
        boolDefaultsKey(.enableStreaming, defaultValue: true)
    }

    var enableStreaming: Bool {
        get { Defaults[enableStreamingKey] }
        set { Defaults[enableStreamingKey] = newValue }
    }

    /// Whether this service exposes the shared reasoning effort picker and
    /// sends the reasoning effort parameters. Defaults to `false`; services
    /// that support reasoning override it to `true` and read `configuredReasoningEffort`
    /// when building their request.
    var supportsReasoningEffort: Bool {
        false
    }

    /// Storage key for the shared `off/high/max` reasoning effort. Named
    /// distinctly from CodexService's CLI-specific `reasoningEffortKey`,
    /// which uses a different effort type, so the two can coexist.
    var reasoningEffortDefaultsKey: Defaults.Key<ReasoningEffort> {
        serviceDefaultsKey(.reasoningEffort, defaultValue: .off)
    }

    var configuredReasoningEffort: ReasoningEffort {
        Defaults[reasoningEffortDefaultsKey]
    }

    @MainActor
    func selectModel(_ identifier: String) {
        if model != identifier { model = identifier }
    }

    func validModels(from supportedModels: String) -> [String] {
        supportedModels.components(separatedBy: ",")
            .map { $0.trim() }.filter { !$0.isEmpty }
    }

    func supportedModels(from validModels: [String]) -> String {
        validModels.joined(separator: ", ")
    }

    /// Base on chat query, convert prompt dict to LLM service prompt model.
    func serviceChatMessageModels(_ chatQuery: ChatQueryParam)
        -> [Any] {
        fatalError(mustOverride)
    }

    /// Words and short phrases get a learner-dictionary entry; everything else is translated.
    func queryType(text: String, from: Language, to: Language) -> EZQueryTextType {
        if !queryType.isEmpty {
            return queryType
        }
        return LearnerDictionary.isDictionaryQuery(text, language: from) ? .dictionary : .translation
    }

    /// Content stream translate.
    /// Content is the original delta text.
    func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: QueryError(
                    type: .api,
                    message:
                    "`\(serviceType().rawValue)` contentStreamTranslate is not implemented"
                )
            )
        }
    }

    // MARK: Private
}
