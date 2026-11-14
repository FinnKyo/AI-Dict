//
//  OpenRouterCatalog.swift
//  AI-Dict
//
//  Fetches OpenRouter's free models, their live availability and the account quota.
//

import Defaults
import Foundation

// MARK: - OpenRouterAvailability

enum OpenRouterAvailability: Int, Codable, Comparable {
    case unknown = 0
    case down = 1
    case unstable = 2
    case available = 3

    // MARK: Internal

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Maps provider endpoint health into one indicator.
    /// OpenRouter reports `status == 0` for healthy endpoints and negative values when degraded.
    static func from(endpoints: [OpenRouterEndpoint]) -> (Self, Double?) {
        guard !endpoints.isEmpty else { return (.down, nil) }

        let uptimes = endpoints.compactMap(\.effectiveUptime)
        let bestUptime = uptimes.max()
        let hasHealthyEndpoint = endpoints.contains { ($0.status ?? 0) >= 0 }

        guard hasHealthyEndpoint else { return (.down, bestUptime) }
        guard let bestUptime else { return (.unknown, nil) }

        switch bestUptime {
        case 95...: return (.available, bestUptime)
        case 70 ..< 95: return (.unstable, bestUptime)
        default: return (.down, bestUptime)
        }
    }
}

// MARK: - OpenRouterFreeModel

struct OpenRouterFreeModel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let contextLength: Int?
    let created: Double?
    let description: String?
    var availability: OpenRouterAvailability = .unknown
    var uptime: Double?
    var providers: [String] = []
    var lastTestLatency: Double?
    var lastTestError: String?

    var author: String {
        id.split(separator: "/").first.map(String.init) ?? id
    }

    /// Model name without the provider prefix and "(free)" suffix, for compact display.
    var shortName: String {
        var value = name
        if let range = value.range(of: ": ") { value = String(value[range.upperBound...]) }
        return value.replacingOccurrences(of: " (free)", with: "")
    }
}

// MARK: - OpenRouterEndpoint

struct OpenRouterEndpoint: Decodable {
    enum CodingKeys: String, CodingKey {
        case providerName = "provider_name"
        case status
        case uptimeLast30m = "uptime_last_30m"
        case uptimeLast1d = "uptime_last_1d"
    }

    let providerName: String?
    let status: Int?
    let uptimeLast30m: Double?
    let uptimeLast1d: Double?

    /// The 30-minute window reports 0 when no traffic was sampled, so fall back to the daily value.
    var effectiveUptime: Double? {
        if let uptimeLast30m, uptimeLast30m > 0 { return uptimeLast30m }
        return uptimeLast1d
    }
}

// MARK: - OpenRouterKeyInfo

struct OpenRouterKeyInfo: Decodable, Equatable {
    enum CodingKeys: String, CodingKey {
        case label
        case limit
        case limitRemaining = "limit_remaining"
        case usage
        case isFreeTier = "is_free_tier"
    }

    let label: String?
    let limit: Double?
    let limitRemaining: Double?
    let usage: Double?
    let isFreeTier: Bool?

    /// Free-model daily request cap documented by OpenRouter: accounts that never bought
    /// credits get 50 requests/day, accounts with purchased credits get 1000.
    var freeModelDailyRequestLimit: Int {
        isFreeTier == false ? 1000 : 50
    }
}

// MARK: - OpenRouterCatalog

/// Talks to the public OpenRouter REST API. All methods are stateless; callers own caching.
enum OpenRouterCatalog {
    // MARK: Internal

    static let baseURL = URL(string: "https://openrouter.ai/api/v1")!
    static let chatCompletionsURL = "https://openrouter.ai/api/v1/chat/completions"
    static let keysPageURL = URL(string: "https://openrouter.ai/settings/keys")!

    /// Returns text-output models whose prompt and completion prices are both zero.
    static func fetchFreeModels() async throws -> [OpenRouterFreeModel] {
        let data = try await get(baseURL.appendingPathComponent("models"), apiKey: nil)
        let response = try JSONDecoder().decode(ModelListResponse.self, from: data)
        return response.data
            .filter(\.isFreeTextModel)
            .map {
                OpenRouterFreeModel(
                    id: $0.id,
                    name: $0.name ?? $0.id,
                    contextLength: $0.contextLength,
                    created: $0.created,
                    description: $0.description
                )
            }
            .sorted { ($0.created ?? 0) > ($1.created ?? 0) }
    }

    /// Fetches provider endpoints for one model and summarises their health.
    static func fetchAvailability(modelID: String) async throws
        -> (OpenRouterAvailability, Double?, [String]) {
        // The model id already contains "author/slug[:variant]", which maps directly to the path.
        let url = baseURL.appendingPathComponent("models/\(modelID)/endpoints")
        let data = try await get(url, apiKey: nil)
        let response = try JSONDecoder().decode(EndpointsResponse.self, from: data)
        let endpoints = response.data.endpoints
        let (availability, uptime) = OpenRouterAvailability.from(endpoints: endpoints)
        let providers = endpoints.compactMap(\.providerName)
        return (availability, uptime, providers)
    }

    /// Reads quota information for the configured API key.
    static func fetchKeyInfo(apiKey: String) async throws -> OpenRouterKeyInfo {
        let data = try await get(baseURL.appendingPathComponent("key"), apiKey: apiKey)
        return try JSONDecoder().decode(KeyResponse.self, from: data).data
    }

    /// Sends a tiny completion and returns the round-trip latency in seconds.
    static func testModel(_ modelID: String, apiKey: String) async throws -> Double {
        var request = URLRequest(url: URL(string: chatCompletionsURL)!, timeoutInterval: 45)
        request.httpMethod = "POST"
        applyHeaders(to: &request, apiKey: apiKey)
        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 16,
            "messages": [["role": "user", "content": "Reply with: OK"]],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let start = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return Date().timeIntervalSince(start)
    }

    static func applyHeaders(to request: inout URLRequest, apiKey: String?) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://github.com/tisfeng/Easydict", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AI-Dict", forHTTPHeaderField: "X-Title")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
    }

    // MARK: Private

    private struct ModelListResponse: Decodable {
        let data: [RemoteModel]
    }

    private struct RemoteModel: Decodable {
        struct Pricing: Decodable {
            let prompt: String?
            let completion: String?
        }

        struct Architecture: Decodable {
            enum CodingKeys: String, CodingKey {
                case outputModalities = "output_modalities"
            }

            let outputModalities: [String]?
        }

        enum CodingKeys: String, CodingKey {
            case id, name, created, description, pricing, architecture
            case contextLength = "context_length"
        }

        let id: String
        let name: String?
        let created: Double?
        let description: String?
        let contextLength: Int?
        let pricing: Pricing?
        let architecture: Architecture?

        var isFreeTextModel: Bool {
            guard let pricing,
                  Double(pricing.prompt ?? "") == 0,
                  Double(pricing.completion ?? "") == 0
            else { return false }
            let outputs = architecture?.outputModalities ?? ["text"]
            return outputs == ["text"]
        }
    }

    private struct EndpointsResponse: Decodable {
        struct Payload: Decodable { let endpoints: [OpenRouterEndpoint] }

        let data: Payload
    }

    private struct KeyResponse: Decodable {
        let data: OpenRouterKeyInfo
    }

    private struct APIErrorEnvelope: Decodable {
        struct Body: Decodable {
            let message: String?
            let code: Int?
        }

        let error: Body
    }

    private static func get(_ url: URL, apiKey: String?) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "GET"
        applyHeaders(to: &request, apiKey: apiKey)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return data
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard !(200 ... 299).contains(http.statusCode) else { return }
        let apiMessage = (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data))?.error.message
        throw OpenRouterError(statusCode: http.statusCode, message: apiMessage)
    }
}

// MARK: - OpenRouterError

struct OpenRouterError: LocalizedError {
    let statusCode: Int
    let message: String?

    var errorDescription: String? {
        let hint = switch statusCode {
        case 401: String(localized: "openrouter.error.unauthorized")
        case 402: String(localized: "openrouter.error.payment_required")
        case 404: String(localized: "openrouter.error.not_found")
        case 429: String(localized: "openrouter.error.rate_limited")
        case 500 ... 599: String(localized: "openrouter.error.provider_down")
        default: ""
        }
        return ["HTTP \(statusCode)", hint, message ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

// MARK: - OpenRouterModelStore

/// Shared, observable cache of the free-model list used by the settings page.
@MainActor
final class OpenRouterModelStore: ObservableObject {
    // MARK: Lifecycle

    private init() {
        if let data = Defaults[.openRouterFreeModelsCache],
           let models = try? JSONDecoder().decode([OpenRouterFreeModel].self, from: data) {
            self.models = models
        }
        self.lastRefresh = Defaults[.openRouterFreeModelsRefreshDate]
    }

    // MARK: Internal

    static let shared = OpenRouterModelStore()

    @Published private(set) var models: [OpenRouterFreeModel] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefresh: Date?
    @Published private(set) var refreshError: String?
    @Published private(set) var keyInfo: OpenRouterKeyInfo?
    @Published private(set) var keyInfoError: String?
    @Published private(set) var testingModelIDs: Set<String> = []

    /// Reloads the free list, then probes each model's endpoint health with limited concurrency.
    func refresh(apiKey: String) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshError = nil
        defer { isRefreshing = false }

        async let keyTask: () = refreshKeyInfo(apiKey: apiKey)

        do {
            var fresh = try await OpenRouterCatalog.fetchFreeModels()
            // Keep previous test results so the list does not flicker.
            let previous = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
            for index in fresh.indices {
                if let old = previous[fresh[index].id] {
                    fresh[index].lastTestLatency = old.lastTestLatency
                    fresh[index].lastTestError = old.lastTestError
                }
            }
            models = fresh
            await probeAvailability()
            lastRefresh = Date()
            persist()
        } catch {
            refreshError = error.localizedDescription
        }

        await keyTask
    }

    func refreshKeyInfo(apiKey: String) async {
        guard !apiKey.trim().isEmpty else {
            keyInfo = nil
            keyInfoError = nil
            return
        }
        do {
            keyInfo = try await OpenRouterCatalog.fetchKeyInfo(apiKey: apiKey)
            keyInfoError = nil
        } catch {
            keyInfo = nil
            keyInfoError = error.localizedDescription
        }
    }

    func test(modelID: String, apiKey: String) async {
        testingModelIDs.insert(modelID)
        defer { testingModelIDs.remove(modelID) }

        var latency: Double?
        var errorText: String?
        do {
            latency = try await OpenRouterCatalog.testModel(modelID, apiKey: apiKey)
        } catch {
            errorText = error.localizedDescription
        }

        guard let index = models.firstIndex(where: { $0.id == modelID }) else { return }
        models[index].lastTestLatency = latency
        models[index].lastTestError = errorText
        if latency != nil, models[index].availability < .unstable {
            models[index].availability = .available
        }
        persist()
    }

    // MARK: Private

    private func probeAvailability() async {
        let ids = models.map(\.id)
        await withTaskGroup(of: (String, OpenRouterAvailability, Double?, [String]).self) { group in
            var iterator = ids.makeIterator()
            let maxConcurrent = 4

            func addNext() {
                guard let id = iterator.next() else { return }
                group.addTask {
                    do {
                        let (availability, uptime, providers) = try await OpenRouterCatalog
                            .fetchAvailability(modelID: id)
                        return (id, availability, uptime, providers)
                    } catch {
                        return (id, .unknown, nil, [])
                    }
                }
            }

            for _ in 0 ..< maxConcurrent { addNext() }
            for await (id, availability, uptime, providers) in group {
                if let index = models.firstIndex(where: { $0.id == id }) {
                    models[index].availability = availability
                    models[index].uptime = uptime
                    models[index].providers = providers
                }
                addNext()
            }
        }
    }

    private func persist() {
        Defaults[.openRouterFreeModelsCache] = try? JSONEncoder().encode(models)
        Defaults[.openRouterFreeModelsRefreshDate] = lastRefresh
    }
}

extension Defaults.Keys {
    static let openRouterFreeModelsCache = Key<Data?>("AIDict_OpenRouterFreeModelsCache", default: nil)
    static let openRouterFreeModelsRefreshDate = Key<Date?>("AIDict_OpenRouterFreeModelsRefreshDate", default: nil)
}
