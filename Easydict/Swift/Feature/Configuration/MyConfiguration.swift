//
//  MyConfiguration.swift
//  Easydict
//
//  Created by ljk on 2024/1/2.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation

// MARK: - MyConfiguration

/// Singleton class to manage application configuration settings.
/// This class uses the `Defaults` library to persist settings and provides
/// reactive updates using Combine.
@objcMembers
class MyConfiguration: NSObject {
    // MARK: Lifecycle

    override private init() {
        super.init()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            observeKeys()
        }
    }

    // MARK: Internal

    private(set) static var shared = MyConfiguration()

    @DefaultsWrapper(.firstLanguage) var firstLanguage: Language
    @DefaultsWrapper(.secondLanguage) var secondLanguage: Language
    @DefaultsWrapper(.queryFromLanguage) var fromLanguage: Language
    @DefaultsWrapper(.queryToLanguage) var toLanguage: Language

    @DefaultsWrapper(.autoShowQueryIcon) var autoSelectText: Bool
    @DefaultsWrapper(.autoShowQueryIconExcludedLanguage) var autoShowQueryIconExcludedLanguage: Language
    @DefaultsWrapper(.autoShowQueryIconMinTextLength) var autoShowQueryIconMinTextLength: Int
    @DefaultsWrapper(.enableForceGetSelectedText) var enableForceGetSelectedText: Bool
    @DefaultsWrapper(.clickQuery) var clickQuery: Bool

    @DefaultsWrapper(.mouseSelectTranslateWindowType) var mouseSelectTranslateWindowType:
        EZWindowType
    @DefaultsWrapper(.shortcutSelectTranslateWindowType) var shortcutSelectTranslateWindowType:
        EZWindowType
    @DefaultsWrapper(.fixedWindowPosition) var fixedWindowPosition: EZShowWindowPosition
    @DefaultsWrapper(.miniWindowPosition) var miniWindowPosition: EZShowWindowPosition
    @DefaultsWrapper(.pinWindowWhenDisplayed) var pinWindowWhenDisplayed
    @DefaultsWrapper(.hideMainWindow) var hideMainWindow: Bool

    @DefaultsWrapper(.clearQueryWhenInputTranslate) var clearInput: Bool
    @DefaultsWrapper(.keepPrevResultWhenSelectTranslateTextIsEmpty) var keepPrevResultWhenEmpty:
        Bool
    @DefaultsWrapper(.selectQueryTextWhenWindowActivate) var selectQueryTextWhenWindowActivate: Bool
    @DefaultsWrapper(.automaticallyRemoveCodeCommentSymbols) var automaticallyRemoveCodeCommentSymbols: Bool
    @DefaultsWrapper(.automaticWordSegmentation) var automaticWordSegmentation: Bool
    @DefaultsWrapper(.replaceNewlineWithSpace) var replaceNewlineWithSpace: Bool
    @DefaultsWrapper(.enableRemoveBooksExcerptInfo) var enableRemoveBooksExcerptInfo: Bool

    @DefaultsWrapper(.autoQueryOCRText) var autoQueryOCRText: Bool
    @DefaultsWrapper(.autoQuerySelectedText) var autoQuerySelectedText: Bool
    @DefaultsWrapper(.autoQueryPastedText) var autoQueryPastedText: Bool
    @DefaultsWrapper(.autoQueryWhenTextChanged) var autoQueryWhenTextChanged: Bool

    @DefaultsWrapper(.autoCopySelectedText) var autoCopySelectedText: Bool
    @DefaultsWrapper(.autoCopyOCRText) var autoCopyOCRText: Bool
    @DefaultsWrapper(.autoCopyFirstTranslatedText) var autoCopyFirstTranslatedText: Bool

    @DefaultsWrapper(.appearanceType) var appearance: AppearanceType
    @DefaultsWrapper(.hideMenuBarIcon) var hideMenuBarIcon: Bool
    @DefaultsWrapper(.fontSizeOptionIndex) var fontSizeIndex: UInt
    @DefaultsWrapper(.enableMarkdownRendering) var enableMarkdownRendering: Bool

    // Advanced Tab
    @DefaultsWrapper(.forceGetSelectedTextType) var forceGetSelectedTextType:
        ForceGetSelectedTextType
    @DefaultsWrapper(.enableOCRTextNormalization) var enableOCRTextNormalization: Bool
    @DefaultsWrapper(.isScreenshotTipLayerHidden) var isScreenshotTipLayerHidden: Bool
    @DefaultsWrapper(.formerFixedScreenVisibleFrame) var formerFixedScreenVisibleFrame: CGRect
    @DefaultsWrapper(.formerMiniScreenVisibleFrame) var formerMiniScreenVisibleFrame: CGRect
    @DefaultsWrapper(.preferAppleScriptAPI) var preferAppleScriptAPI: Bool

    // Max window height percentage, e.g., 80 means 80% of the screen height
    @DefaultsWrapper(.maxWindowHeightPercentage) var maxWindowHeightPercentage: Int

    @ShortcutWrapper(.pinShortcut) var pinShortcutString: String

    let fontSizes: [CGFloat] = [1, 1.1, 1.2, 1.3, 1.4]
    var disabledAutoSelect: Bool = false
    var isRecordingSelectTextShortcutKey: Bool = false
    var cancellables: Set<AnyCancellable> = []

    var fontSizeRatio: CGFloat {
        let safeIndex = max(0, min(Int(fontSizeIndex), fontSizes.count - 1))
        return fontSizes[safeIndex]
    }

    static func destroySharedInstance() {
        shared = MyConfiguration()
    }

    // MARK: Private

    /// Observes only the settings whose change needs an immediate side effect.
    private func observeKeys() {
        Defaults.publisher(.autoShowQueryIcon, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                EventMonitor.shared.addBothMonitor(autoSelectText)
            }
            .store(in: &cancellables)

        Defaults.publisher(.clickQuery, options: [])
            .removeDuplicates()
            .sink { _ in
                EZWindowManager.shared().updatePopButtonQueryAction()
            }
            .store(in: &cancellables)

        Defaults.publisher(.hideMainWindow, options: [])
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                let windowManger = EZWindowManager.shared()
                windowManger.updatePopButtonQueryAction()
                if hideMainWindow {
                    windowManger.destroyMainWindow()
                }
            }
            .store(in: &cancellables)

        Defaults.publisher(.fontSizeOptionIndex, options: [])
            .removeDuplicates()
            .sink { _ in
                NotificationCenter.default.post(name: .didChangeFontSize, object: nil)
            }
            .store(in: &cancellables)

        Defaults.publisher(.appearanceType, options: [])
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { change in
                DarkModeManager.shared.updateDarkMode(change.newValue)
            }
            .store(in: &cancellables)

        Defaults.publisher(.pinShortcut, options: [])
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                EZWindowManager.shared().updateWindowsTitlebarButtonsToolTip()
            }
            .store(in: &cancellables)
    }
}
