//
//  ServiceTab.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI

// MARK: - ServiceTab

/// AI-Dict has a single translation service, so this tab is its configuration page.
struct ServiceTab: View {
    // MARK: Internal

    var body: some View {
        Form {
            OpenRouterConfigurationView(service: service)
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    @State private var service = OpenRouterService()
}

#Preview {
    ServiceTab()
}
