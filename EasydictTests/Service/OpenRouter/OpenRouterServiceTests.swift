//
//  OpenRouterServiceTests.swift
//  EasydictTests
//
//  Configuration, registration and real-network checks for the OpenRouter service.
//

import Testing

@testable import Easydict

@Suite("OpenRouterService", .serialized)
struct OpenRouterServiceTests {
    @Test("exposes OpenRouter's OpenAI-compatible configuration")
    func serviceConfiguration() {
        let service = OpenRouterService()

        #expect(service.serviceType() == .openRouter)
        #expect(service.apiKeyRequirement() == .userProvided)
        #expect(service.isStream())
        #expect(service.defaultEndpoint == "https://openrouter.ai/api/v1/chat/completions")
        #expect(service.defaultModel == "openrouter/free")
        #expect(!service.name().isEmpty)
    }

    @Test("is registered in the query service factory")
    func factoryRegistration() {
        let service = QueryServiceFactory.shared.service(withTypeId: ServiceType.openRouter.rawValue)
        #expect(service is OpenRouterService)
    }

    @Test("detects foreign words as dictionary queries")
    func dictionaryQueryType() {
        let service = OpenRouterService()

        #expect(service.supportedQueryType() == [.translation, .dictionary])
        #expect(service.queryType(text: "食べる", from: .japanese, to: .simplifiedChinese) == .dictionary)
        #expect(service.queryType(text: "Schadenfreude", from: .german, to: .simplifiedChinese) == .dictionary)
        #expect(service.queryType(
            text: "Ich habe heute keine Zeit für dich",
            from: .german,
            to: .simplifiedChinese
        ) == .translation)
    }

    @Test("routes words to the learner dictionary and sentences to plain translation")
    func promptRouting() {
        let dictionary = OpenRouterService().chatMessageDicts(.init(
            text: "Haus", sourceLanguage: .german, targetLanguage: .simplifiedChinese,
            queryType: .dictionary, enableSystemPrompt: true
        ))
        #expect(dictionary.contains { $0.content.contains("Duden") })

        let translation = OpenRouterService().chatMessageDicts(.init(
            text: "Ich habe heute keine Zeit.", sourceLanguage: .german, targetLanguage: .simplifiedChinese,
            queryType: .translation, enableSystemPrompt: true
        ))
        #expect(translation.last?.content.hasPrefix("Translate the following German text") == true)
        #expect(!translation.contains { $0.content.contains("Duden") })
    }

    @Test("lists free text models from the live OpenRouter catalog", .tags(.integration))
    func fetchesFreeModels() async throws {
        let models = try await OpenRouterCatalog.fetchFreeModels()

        #expect(!models.isEmpty)
        #expect(models.allSatisfy { !$0.id.isEmpty })
    }

    @Test("reads live endpoint health for a free model", .tags(.integration))
    func fetchesAvailability() async throws {
        let models = try await OpenRouterCatalog.fetchFreeModels()
        let model = try #require(models.first { $0.id.hasSuffix(":free") })
        let (_, _, providers) = try await OpenRouterCatalog.fetchAvailability(modelID: model.id)

        #expect(!providers.isEmpty)
    }

    @Test(
        "returns a fixed-layout dictionary entry with configured credentials",
        .tags(.integration, .requiresLocalEnvironment)
    )
    func dictionaryLookup() async throws {
        let service = OpenRouterService()
        let result = try await service.translate("apple", from: .english, to: .simplifiedChinese)
        let text = try #require(result.translatedText)

        #expect(text.contains("###"), "Expected Markdown sections, got: \(text)")
        #expect(text.contains("/"), "Expected IPA pronunciation, got: \(text)")
        #expect(!text.contains("⟨"), "Placeholders were not filled: \(text)")
    }
}
