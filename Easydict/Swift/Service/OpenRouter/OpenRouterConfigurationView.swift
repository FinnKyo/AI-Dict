//
//  OpenRouterConfigurationView.swift
//  AI-Dict
//
//  Settings page for the OpenRouter service: API key, account quota and the live free-model list.
//

import Defaults
import SwiftUI

// MARK: - OpenRouterConfigurationView

struct OpenRouterConfigurationView: View {
    // MARK: Lifecycle

    init(service: OpenRouterService) {
        self.service = service
        self._apiKey = .init(service.apiKeyKey)
        self._selectedModel = .init(service.modelKey)
    }

    // MARK: Internal

    let service: OpenRouterService

    var body: some View {
        Group {
            ServiceConfigurationSecretSectionView(service: service, observeKeys: service.observeKeys) {
                SecureInputCell(
                    textFieldTitleKey: "service.configuration.openai.api_key.title",
                    key: service.apiKeyKey,
                    placeholder: service.apiKeyPlaceholder
                )
            }

            accountSection
            modelsSection
        }
        .task {
            // Show the cached list immediately, then refresh in the background once per open.
            await store.refresh(apiKey: apiKey)
            service.syncSupportedModels(with: store.models.map(\.id))
        }
        .onChange(of: apiKey) { newValue in
            Task { await store.refreshKeyInfo(apiKey: newValue) }
        }
    }

    // MARK: Private

    private enum SortOrder: String, CaseIterable, Identifiable {
        case availability
        case newest
        case context

        // MARK: Internal

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .availability: "openrouter.sort.availability"
            case .newest: "openrouter.sort.newest"
            case .context: "openrouter.sort.context"
            }
        }
    }

    @ObservedObject private var store = OpenRouterModelStore.shared
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .availability

    @Default private var apiKey: String
    @Default private var selectedModel: String

    private var displayedModels: [OpenRouterFreeModel] {
        let query = searchText.trim().lowercased()
        let filtered = store.models.filter { model in
            model.id != OpenRouterService.autoFreeModelID
                && (query.isEmpty || model.id.lowercased().contains(query) || model.name.lowercased().contains(query))
        }
        switch sortOrder {
        case .availability:
            return filtered.sorted {
                if $0.availability != $1.availability { return $0.availability > $1.availability }
                return ($0.uptime ?? 0) > ($1.uptime ?? 0)
            }
        case .newest:
            return filtered.sorted { ($0.created ?? 0) > ($1.created ?? 0) }
        case .context:
            return filtered.sorted { ($0.contextLength ?? 0) > ($1.contextLength ?? 0) }
        }
    }

    private var accountSection: some View {
        Section {
            if apiKey.trim().isEmpty {
                HStack {
                    Text("openrouter.account.no_key")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link(destination: OpenRouterCatalog.keysPageURL) {
                        Text("openrouter.account.get_key")
                    }
                }
            } else if let info = store.keyInfo {
                LabeledContent("openrouter.account.tier") {
                    Text(info.isFreeTier == false ? "openrouter.account.tier.paid" : "openrouter.account.tier.free")
                }
                LabeledContent("openrouter.account.daily_limit") {
                    Text(verbatim: "\(info.freeModelDailyRequestLimit) / day")
                        .monospacedDigit()
                }
                if let usage = info.usage {
                    LabeledContent("openrouter.account.usage") {
                        Text(verbatim: String(format: "$%.4f", usage))
                            .monospacedDigit()
                    }
                }
                if let remaining = info.limitRemaining {
                    LabeledContent("openrouter.account.remaining") {
                        Text(verbatim: String(format: "$%.4f", remaining))
                            .monospacedDigit()
                    }
                }
            } else if let error = store.keyInfoError {
                Text(verbatim: error)
                    .foregroundStyle(.red)
                    .font(.callout)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        } header: {
            Text("openrouter.account.title")
        } footer: {
            Text("openrouter.account.footer")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var modelsSection: some View {
        Section {
            HStack(spacing: 8) {
                TextField("openrouter.models.search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Picker("", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
                .labelsHidden()
                .fixedSize()
                Button {
                    Task {
                        await store.refresh(apiKey: apiKey)
                        service.syncSupportedModels(with: store.models.map(\.id))
                    }
                } label: {
                    if store.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("openrouter.models.refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(store.isRefreshing)
            }

            if let error = store.refreshError {
                Text(verbatim: error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            autoRouterRow

            ForEach(displayedModels) { model in
                OpenRouterModelRow(
                    model: model,
                    isSelected: model.id == selectedModel,
                    isTesting: store.testingModelIDs.contains(model.id),
                    canTest: !apiKey.trim().isEmpty,
                    onSelect: { select(model.id) },
                    onTest: { Task { await store.test(modelID: model.id, apiKey: apiKey) } }
                )
            }

            if displayedModels.isEmpty, !store.isRefreshing {
                Text("openrouter.models.empty")
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("openrouter.models.title \(store.models.count)")
                Spacer()
                if let date = store.lastRefresh {
                    Text("openrouter.models.updated \(date.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("openrouter.models.footer")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    /// `openrouter/free` lets OpenRouter pick any healthy free model per request.
    private var autoRouterRow: some View {
        HStack {
            Image(systemName: selectedModel == OpenRouterService.autoFreeModelID ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectedModel == OpenRouterService.autoFreeModelID ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("openrouter.models.auto.title")
                Text(verbatim: OpenRouterService.autoFreeModelID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { select(OpenRouterService.autoFreeModelID) }
    }

    private func select(_ modelID: String) {
        service.syncSupportedModels(with: store.models.map(\.id))
        service.model = modelID
        selectedModel = modelID
    }
}

// MARK: - OpenRouterModelRow

private struct OpenRouterModelRow: View {
    // MARK: Internal

    let model: OpenRouterFreeModel
    let isSelected: Bool
    let isTesting: Bool
    let canTest: Bool
    let onSelect: () -> ()
    let onTest: () -> ()

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .help(Text(statusHelp))
                    Text(verbatim: model.shortName)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .lineLimit(1)
                }
                Text(verbatim: detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let testLine {
                    Text(verbatim: testLine)
                        .font(.caption)
                        .foregroundStyle(model.lastTestError == nil ? Color.green : Color.red)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Button {
                onTest()
            } label: {
                if isTesting {
                    ProgressView().controlSize(.small)
                } else {
                    Text("openrouter.models.test")
                }
            }
            .disabled(!canTest || isTesting)
            .help(Text(canTest ? "openrouter.models.test.help" : "openrouter.account.no_key"))
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    // MARK: Private

    private var statusColor: Color {
        switch model.availability {
        case .available: .green
        case .unstable: .yellow
        case .down: .red
        case .unknown: .gray
        }
    }

    private var statusHelp: LocalizedStringKey {
        switch model.availability {
        case .available: "openrouter.status.available"
        case .unstable: "openrouter.status.unstable"
        case .down: "openrouter.status.down"
        case .unknown: "openrouter.status.unknown"
        }
    }

    private var detailLine: String {
        var parts = [model.id]
        if let context = model.contextLength {
            parts.append(context >= 1000 ? "\(context / 1000)K ctx" : "\(context) ctx")
        }
        if let uptime = model.uptime {
            parts.append(String(format: "uptime %.1f%%", uptime))
        }
        if !model.providers.isEmpty {
            parts.append(model.providers.joined(separator: ", "))
        }
        return parts.joined(separator: " · ")
    }

    private var testLine: String? {
        if let error = model.lastTestError { return "✕ \(error)" }
        if let latency = model.lastTestLatency { return String(format: "✓ %.2fs", latency) }
        return nil
    }
}
