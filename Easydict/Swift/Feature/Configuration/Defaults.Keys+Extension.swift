//
//  Configuration+Defaults.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/12.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import Magnet

/// Utils
extension Defaults.Keys {
    /// is first launch
    static let firstLaunch = Key<Bool>("EZConfiguration_kFirstLaunch", default: true)
}

// Setting
extension Defaults.Keys {
    // rename `from`
    static let queryFromLanguage = Key<Language>("EZConfiguration_kFromKey", default: .auto)
    // rename `to`
    static let queryToLanguage = Key<Language>("EZConfiguration_kToKey", default: .auto)

    static let firstLanguage = Key<Language>(
        "EZConfiguration_kFirstLanguageKey",
        default: EZLanguageManager.shared().systemPreferredTwoLanguages[0]
    )
    static let secondLanguage = Key<Language>(
        "EZConfiguration_kSecondLanguageKey",
        default: EZLanguageManager.shared().systemPreferredTwoLanguages[1]
    )

    static let autoShowQueryIcon = Key<Bool>("EZConfiguration_kAutoSelectTextKey", default: true)
    static let autoShowQueryIconExcludedLanguage = Key<Language>(
        "EZConfiguration_kAutoShowQueryIconExcludedLanguageKey",
        default: Defaults[.firstLanguage]
    )
    static let autoShowQueryIconMinTextLength = Key<Int>(
        "EZConfiguration_kAutoShowQueryIconMinTextLengthKey",
        default: 0
    )
    static let clickQuery = Key<Bool>("EZConfiguration_kClickQueryKey", default: false)
    static let hideMainWindow = Key<Bool>("EZConfiguration_kHideMainWindowKey", default: true)
    static let autoQueryOCRText = Key<Bool>("EZConfiguration_kAutoQueryOCTTextKey", default: true)
    static let autoQuerySelectedText = Key<Bool>(
        "EZConfiguration_kAutoQuerySelectedTextKey", default: true
    )
    static let autoQueryPastedText = Key<Bool>(
        "EZConfiguration_kAutoQueryPastedTextKey", default: false
    )
    static let autoQueryWhenTextChanged = Key<Bool>(
        "EZConfiguration_kAutoQueryWhenTextChangedKey", default: false
    )
    static let autoCopyOCRText = Key<Bool>("EZConfiguration_kAutoCopyOCRTextKey", default: false)
    static let autoCopySelectedText = Key<Bool>(
        "EZConfiguration_kAutoCopySelectedTextKey", default: false
    )
    static let autoCopyFirstTranslatedText = Key<Bool>(
        "EZConfiguration_kAutoCopyFirstTranslatedTextKey",
        default: false
    )
    static let hideMenuBarIcon = Key<Bool>("EZConfiguration_kHideMenuBarIconKey", default: false)
    static let fixedWindowPosition = Key<EZShowWindowPosition>(
        "EZConfiguration_kShowFixedWindowPositionKey",
        default: .right
    )
    static let miniWindowPosition = Key<EZShowWindowPosition>(
        "EZConfiguration_kShowMiniWindowPositionKey",
        default: .mouse
    )
    static let mouseSelectTranslateWindowType = Key<EZWindowType>(
        "EZConfiguration_kMouseSelectTranslateWindowTypeKey",
        default: .fixed
    )
    static let shortcutSelectTranslateWindowType = Key<EZWindowType>(
        "EZConfiguration_kShortcutSelectTranslateWindowTypeKey",
        default: .fixed
    )
    static let pinWindowWhenDisplayed = Key<Bool>(
        "EZConfiguration_kPinWindowWhenDisplayed", default: false
    )

    static let clearQueryWhenInputTranslate = Key<Bool>(
        "EZConfiguration_kClearInputKey", default: false
    )
    static let keepPrevResultWhenSelectTranslateTextIsEmpty = Key<Bool>(
        "EZConfiguration_kKeepPrevResultKey",
        default: true
    )
    static let selectQueryTextWhenWindowActivate = Key<Bool>(
        "EZConfiguration_kSelectQueryTextWhenWindowActivate",
        default: false
    )

    static let appearanceType = Key<AppearanceType>(
        "EZConfiguration_kApperanceKey", default: .followSystem
    )
    static let fontSizeOptionIndex = Key<UInt>(
        "EZConfiguration_kTranslationControllerFontKey", default: 0
    )
    static let selectedMenuBarIcon = Key<MenuBarIconType>(
        "EZConfiguration_kSelectedMenuBarIconKey", default: .square
    )

    static let automaticWordSegmentation = Key<Bool>(
        "EZConfiguration_kAutomaticWordSegmentation", default: true
    )
    static let automaticallyRemoveCodeCommentSymbols = Key<Bool>(
        "EZConfiguration_kAutomaticallyRemoveCodeCommentSymbols",
        default: true
    )
    static let replaceNewlineWithSpace = Key<Bool>(
        "EZConfiguration_kReplaceNewlineWithSpace", default: false
    )

    static var enableOCRTextNormalization = Key<Bool>(
        "enableOCRTextNormalization", default: false
    )
    static var showOCRMenuItems = Key<Bool>(
        "showOCRMenuItems", default: false
    )
    /// Controls whether the screenshot tip layer is hidden during capture.
    static var isScreenshotTipLayerHidden = Key<Bool>(
        "isScreenshotTipLayerHidden", default: false
    )

    static let enableForceGetSelectedText = Key<Bool>(
        "EZConfiguration_kForceAutoGetSelectedText",
        default: true
    )
    static var forceGetSelectedTextType = Key<ForceGetSelectedTextType>(
        "EZConfiguration_kForceGetSelectedTextTypeKey",
        default: .menuBarActionCopy
    )

    static let enableRemoveBooksExcerptInfo = Key<Bool>(
        "EZConfiguration_kEnableRemoveBooksExcerptInfo",
        default: true
    )

    /// Whether AI/streaming service results should render Markdown formatting
    /// (headings, bold, lists, blockquotes, code) in the result label.
    static let enableMarkdownRendering = Key<Bool>(
        "EZConfiguration_kEnableMarkdownRendering",
        default: true
    )

    static let preferAppleScriptAPI = Key<Bool>(
        "EZConfiguration_kPreferAppleScriptAPI",
        default: true
    )

    /// Cannot use NSScreen, so we use CGRect to record the screen visible frame for EZShowWindowPositionFormer
    static var formerFixedScreenVisibleFrame = Key<CGRect>(
        "EZConfiguration_kScreenVisibleFrameKey", default: .zero
    )

    static var formerMiniScreenVisibleFrame = Key<CGRect>(
        "EZConfiguration_kFormerMiniScreenVisibleFrameKey",
        default: .zero
    )

    // MARK: - Window Height Limit

    // Key for storing the selected max window height percentage, default is 100%.
    // Storing as Int (e.g., 50, 80, 100).
    static let maxWindowHeightPercentage = Key<Int>("maxWindowHeightPercentage", default: 100)
}

extension Defaults.Keys {
    static func windowFrame(for windowType: EZWindowType) -> Key<CGRect> {
        let key = "EZConfiguration_kWindowFrameKey_\(windowType)"
        return .init(key, default: .zero)
    }
}

// MARK: - EZQueryTextType + Defaults.Serializable

extension EZQueryTextType: Defaults.Serializable {
    public static var bridge: Bridge = .init()

    public struct Bridge: Defaults.Bridge {
        public typealias Value = EZQueryTextType

        public typealias Serializable = String

        public func serialize(_ value: EZQueryTextType?) -> String? {
            guard let value else { return "7" }
            return "\(value.rawValue)"
        }

        public func deserialize(_ object: String?) -> EZQueryTextType? {
            guard let object else { return nil }
            return EZQueryTextType(rawValue: UInt(object) ?? 7)
        }
    }
}

// MARK: - CGRect + Defaults.Serializable

extension CGRect: Defaults.Serializable {
    public static var bridge: Bridge = .init()

    public struct Bridge: Defaults.Bridge {
        public typealias Value = CGRect

        public typealias Serializable = String

        public func serialize(_ value: CGRect?) -> String? {
            let value = value ?? .zero
            return NSStringFromRect(value)
        }

        public func deserialize(_ object: String?) -> CGRect? {
            guard let object else { return nil }
            return NSRectFromString(object)
        }
    }
}

// MARK: - DefaultsWrapper

@propertyWrapper
class DefaultsWrapper<T: Defaults.Serializable> {
    // MARK: Lifecycle

    init(_ key: Defaults.Key<T>) {
        self.key = key
    }

    // MARK: Internal

    let key: Defaults.Key<T>

    var wrappedValue: T {
        get {
            Defaults[key]
        }
        set {
            Defaults[key] = newValue
        }
    }
}

// MARK: - ShortcutWrapper

@propertyWrapper
class ShortcutWrapper<T: KeyCombo> {
    // MARK: Lifecycle

    init(_ key: Defaults.Key<T?>) {
        self.key = key
    }

    // MARK: Internal

    let key: Defaults.Key<T?>

    var wrappedValue: String {
        let keyCombo = Defaults[key]
        if let keyCombo, keyCombo.doubledModifiers {
            return keyCombo.keyEquivalentModifierMaskString
                + keyCombo.keyEquivalentModifierMaskString
        }
        return (keyCombo?.keyEquivalentModifierMaskString ?? "") + (keyCombo?.keyEquivalent ?? "")
    }
}

/// shortcut
extension Defaults.Keys {
    // Global
    static let selectionShortcut = Key<KeyCombo?>("EZSelectionShortcutKey_keyHolder")
    static let toggleAutoSelectTextShortcut = Key<KeyCombo?>(
        "EZToggleAutoSelectTextShortcutKey_keyHolder"
    )
    static let snipShortcut = Key<KeyCombo?>("EZSnipShortcutKey_keyHolder")
    static let inputShortcut = Key<KeyCombo?>("EZInputShortcutKey_keyHolder")
    // Note: This key value is not suitable for renaming, because it is used in old versions.
    static let silentScreenshotOCRShortcut = Key<KeyCombo?>("EZScreenshotOCRShortcutKey_keyHolder")
    static let showMiniWindowShortcut = Key<KeyCombo?>("EZShowMiniShortcutKey_keyHolder")
    static let pasteboardTranslateShortcut = Key<KeyCombo?>(
        "EZPasteboardTranslateShortcutKey_keyHolder"
    )

    static let screenshotOCRShortcut = Key<KeyCombo?>("EZScreenshotOCRShortcutKey2_keyHolder")
    static let pasteboardOCRShortcut = Key<KeyCombo?>("EZPasteboardOCRShortcutKey_keyHolder")
    static let showOCRWindowShortcut = Key<KeyCombo?>("EZShowOCRWindowShortcutKey_keyHolder")

    // App
    static let clearInputShortcut = Key<KeyCombo?>("EZClearInputShortcutKey_keyHolder")
    static let clearAllShortcut = Key<KeyCombo?>("EZClearAllShortcutKey_keyHolder")
    static let copyShortcut = Key<KeyCombo?>("EZCopyShortcutKey_keyHolder")
    static let copyFirstResultShortcut = Key<KeyCombo?>("EZCopyFirstResultShortcutKey_keyHolder")
    static let focusShortcut = Key<KeyCombo?>("EZFocusShortcutKey_keyHolder")
    static let retryShortcut = Key<KeyCombo?>("EZRetryShortcutKey_keyHolder")
    static let toggleShortcut = Key<KeyCombo?>("EZToggleShortcutKey_keyHolder")
    static let pinShortcut = Key<KeyCombo?>("EZPinShortcutKey_keyHolder")
    static let hideShortcut = Key<KeyCombo?>("EZHideShortcutKey_keyHolder")
    static let increaseFontSize = Key<KeyCombo?>("EZIncreaseFontSizeShortcutKey_keyHolder")
    static let decreaseFontSize = Key<KeyCombo?>("EZDecreaseFontSizeShortcutKey_keyHolder")
}
