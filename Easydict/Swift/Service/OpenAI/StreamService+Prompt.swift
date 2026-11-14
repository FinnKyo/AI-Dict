//
//  StreamService+Prompt.swift
//  Easydict
//
//  Created by tisfeng on 2024/1/1.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension StreamService {
    static let translationSystemPrompt = """
    You are a translation expert proficient in various languages, focusing solely on translating text without interpretation. You accurately understand the meanings of proper nouns, idioms, metaphors, allusions, and other obscure words in sentences, translating them appropriately based on the context and language environment. The translation should be natural and fluent. Only return the translated text, without including redundant quotes or additional notes.
    """

    /// AI-Dict has exactly two query modes: a learner-dictionary entry for words and short
    /// phrases, and a plain translation for everything else.
    func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        if chatQuery.queryType == .dictionary {
            return LearnerDictionary.messages(
                word: chatQuery.text,
                sourceLanguage: chatQuery.sourceLanguage,
                nativeLanguage: MyConfiguration.shared.firstLanguage
            )
        }
        return translationMessages(chatQuery)
    }

    func translationMessages(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        let (text, sourceLanguage, targetLanguage, _, enableSystemPrompt) = chatQuery.unpack()

        // Wrap user input in """ so instructions inside it are treated as text to translate.
        let prompt = "Translate the following \(sourceLanguage.queryLanguageName) text into \(targetLanguage.queryLanguageName) text: \"\"\"\(text)\"\"\""

        var messages: [ChatMessage] = enableSystemPrompt
            ? [.init(role: .system, content: StreamService.translationSystemPrompt)]
            : []
        messages.append(.init(role: .user, content: prompt))
        return messages
    }
}

extension Language {
    var queryLanguageName: String {
        switch self {
        case .simplifiedChinese:
            "Simplified Chinese (简体中文)"
        case .traditionalChinese:
            "Traditional Chinese (繁體中文)"
        default:
            rawValue.replacingOccurrences(of: "-", with: " ")
        }
    }
}
