//
//  SystemUtility+AX.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/2.
//  Copyright © 2025 izual. All rights reserved.
//

import AXSwift
import Foundation
import SelectedTextKit

extension SystemUtility {
    /// Determine whether inserting/replacing text is likely supported in the current context.
    ///
    /// The primary signal is whether the focused UI element can be identified as a text input element.
    /// For apps that don't expose reliable focused-role information via Accessibility (e.g. WeChat),
    /// this falls back to checking whether the standard "Paste" menu item is enabled.
    ///
    /// - Returns: `true` when insertion is likely supported; otherwise `false`.
    func canInsertText() -> Bool {
        logInfo("Checking if text insertion is supported in current context")

        if let element = try? focusedTextFieldElement() {
            return isEditableTextInputElement(element)
        }

        guard bundleIDAllowListForPasteMenuCheck.contains(frontmostAppBundleID) else {
            return false
        }

        do {
            _ = try axManager.findMenuItem(.paste, requireEnabled: true)
            return true
        } catch {
            logInfo("Paste menu item is not available or not enabled: \(error)")
            return false
        }
    }

    /// Determine whether the focused element is a selectable text element.
    ///
    /// This is used to gate auto query icon display. If the focused element cannot be
    /// resolved via Accessibility APIs, an allowlist can be used to bypass the check.
    func isFocusedSelectableTextElement() -> Bool {
        do {
            guard let focusedUIElement = try frontmostAppElement?.focusedUIElement() else {
                logInfo("No focused UI element found: \(String(describing: frontmostAppElement)), treat as selectable")
                return true
            }

            let roleValue = try? focusedUIElement.roleValue()
            logInfo("Focused UI element role: \(roleValue ?? "nil")")

            if let roleValue, selectableTextRoles.contains(roleValue) {
                logInfo("Focused UI element role is in selectable text allowlist, treat as selectable")
                return true
            }

            if (try? focusedUIElement.selectedTextRange()) != nil {
                logInfo("Focused UI element has selectable text range, treat as selectable")
                return true
            }

            if let value = try? focusedUIElement.value(), !value.isEmpty {
                logInfo("Focused UI element has non-empty value, treat as selectable")
                return true
            }

            if bundleIDAllowListForSelectableTextCheck.contains(frontmostAppBundleID) {
                logInfo("Frontmost app is in selectable text check allowlist, treat as selectable")
                return true
            }

            logInfo("Focused UI element not selectable text role: \(roleValue ?? "nil")")
            return false
        } catch {
            logError("Error accessing focused UI element: \(error)")
            return false
        }
    }

    /// Get the currently focused text field element, use AXSwift API
    ///
    /// - NOTE: May return nil if no focused text field is found, if not supported AX
    func focusedTextFieldElement() throws -> UIElement? {
        do {
            guard let focusedUIElement = try frontmostAppElement?.focusedUIElement() else {
                logInfo("No focused UI element found: \(String(describing: frontmostAppElement))")
                return nil
            }

            guard let roleValue = try focusedUIElement.roleValue() else {
                logInfo("Focused UI element has no role attribute")
                return nil
            }

            if textFieldRoles.contains(roleValue) {
                return focusedUIElement
            }
            logInfo("Focused UI element not a text field role: \(roleValue)")
            return nil
        } catch {
            logError("Error accessing focused UI element: \(error)")
            return nil
        }
    }

    /// A `UIElement` for frontmost application.
    var frontmostAppElement: UIElement? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        return Application(frontmostApp)
    }

    // MARK: Private

    /// Roles that are considered text fields
    private var textFieldRoles: Set<String> {
        [
            kAXTextFieldRole,
            kAXTextAreaRole,
            kAXComboBoxRole, // Safari: Google search field
            kAXSearchFieldSubrole,
            kAXPopUpButtonRole,
            kAXMenuRole,
        ]
    }

    private var selectableTextRoles: Set<String> {
        textFieldRoles.union([
            kAXStaticTextRole,
            kAXGroupRole, // PDF, fix https://github.com/tisfeng/Easydict/issues/1091
            Role.webArea.rawValue,
        ])
    }

    private func isEditableTextInputElement(_ element: UIElement) -> Bool {
        // !!!: `enabled` is not reliable for some apps, e.g. ChatGPT app.
//        if element.boolAttribute(.enabled) != true {
//            logInfo("Focused text input element is not enabled")
//            return false
//        }

        let isSettable = try? element.attributeIsSettable(.value)

        if isSettable != true {
            logInfo("Focused text input element is not editable")
            return false
        }

        return true
    }

    // MARK: - Objective-C AX Wrappers

    @objc
    func hasEnabledCopyMenuItem() -> Bool {
        (try? axManager.findEnabledMenuItem(.copy)) != nil
    }

    /// Check if there is a focused text field element
    @objc
    func isFocusedTextField() -> Bool {
        (try? focusedTextFieldElement()) != nil
    }

    @objc
    func getSelectedTextFrame() -> NSRect {
        (try? axManager.getSelectedTextFrame().rectValue) ?? .zero
    }
}

extension UIElement {
    func boolAttribute(_ attribute: Attribute) -> Bool? {
        guard let value: Any = try? self.attribute(attribute) else {
            return nil
        }

        if let bool = value as? Bool {
            return bool
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        return nil
    }
}
