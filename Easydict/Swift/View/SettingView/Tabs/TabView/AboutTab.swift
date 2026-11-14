//
//  AboutTab.swift
//  AI-Dict
//
//  Created by Kyle on 2023/10/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - AboutTab

struct AboutTab: View {
    // MARK: Internal

    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "AI-Dict")
                    .font(.system(size: 35, weight: .medium))
                    .padding(.bottom, 3)

                Text("current_version \(version)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)

                Text("setting.about.based_on_easydict")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 20)

                HStack(spacing: 15) {
                    Button {
                        NSWorkspace.shared.open(AppConstants.upstreamRepoURL)
                    } label: {
                        Label("setting.about.easydict_link", systemSymbol: .chevronLeftForwardslashChevronRight)
                    }

                    Button {
                        HostWindowManager.shared.showAcknowWindow()
                    } label: {
                        Label("setting.about.acknowledgements", systemSymbol: .checkmarkSealFill)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: Private

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

#Preview {
    AboutTab()
}
