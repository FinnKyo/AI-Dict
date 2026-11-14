//
//  ChatMessage.swift
//  Easydict
//
//  Created by tisfeng on 2024/11/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - ChatMessage

struct ChatMessage {
    // MARK: - ChatRole

    enum ChatRole: String, Codable, Equatable, CaseIterable {
        case system
        case user
        case assistant
        case tool
    }

    let role: ChatRole
    let content: String
}

// MARK: - ChatQueryParam

struct ChatQueryParam {
    let text: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let queryType: EZQueryTextType
    let enableSystemPrompt: Bool

    func unpack() -> (String, Language, Language, EZQueryTextType, Bool) {
        (text, sourceLanguage, targetLanguage, queryType, enableSystemPrompt)
    }
}
