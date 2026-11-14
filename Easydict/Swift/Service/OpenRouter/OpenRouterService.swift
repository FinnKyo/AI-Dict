//
//  OpenRouterService.swift
//  AI-Dict
//
//  OpenRouter free models as the translation/dictionary engine.
//

import Defaults
import Foundation
import OpenAI
import SwiftUI

// MARK: - OpenRouterService

@objc(EZOpenRouterService)
class OpenRouterService: BaseOpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("openrouter_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .openRouter
    }

    public override func link() -> String? {
        "https://openrouter.ai/models?max_price=0"
    }

    public override func configurationListItems() -> Any? {
        OpenRouterConfigurationView(service: self)
    }

    // MARK: Internal

    /// `openrouter/free` routes to any currently available free model, so it is a safe default
    /// before the user has refreshed the list for the first time.
    static let autoFreeModelID = "openrouter/free"

    override var defaultModels: [String] {
        [Self.autoFreeModelID]
    }

    override var defaultModel: String {
        Self.autoFreeModelID
    }

    override var defaultEndpoint: String {
        OpenRouterCatalog.chatCompletionsURL
    }

    /// Free reasoning models can think for tens of seconds before the first visible token.
    /// A dictionary or translation lookup needs no chain of thought, so reasoning is always off.
    @nonobjc
    override var reasoningEffort: ChatQuery.ReasoningEffort? {
        ChatQuery.ReasoningEffort.none
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    /// Keeps the selectable model list equal to the latest free list, so the stored
    /// selection survives `StreamService.model`'s validity check.
    func syncSupportedModels(with freeModelIDs: [String]) {
        var seen = Set<String>()
        let ids = ([Self.autoFreeModelID] + freeModelIDs).filter { seen.insert($0).inserted }
        let current = model
        supportedModels = supportedModels(from: ids)
        if ids.contains(current) {
            model = current
        }
    }
}
