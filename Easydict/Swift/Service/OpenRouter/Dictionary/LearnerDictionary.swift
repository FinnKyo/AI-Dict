//
//  LearnerDictionary.swift
//  AI-Dict
//
//  Builds fixed-format, learner-oriented dictionary prompts. Each supported headword language
//  has its own template modelled on an established learner's dictionary for that language.
//

import CoreServices
import Foundation
import NaturalLanguage

// MARK: - LearnerDictTemplate

struct LearnerDictTemplate {
    struct Heading {
        let zh: String
        let en: String
    }

    struct Section {
        let heading: Heading
        /// Markdown skeleton with ⟨placeholders⟩ the model must fill.
        let body: String
    }

    /// Languages whose headwords use this template.
    let languages: Set<Language>
    /// Display name used inside the prompt, e.g. "Japanese".
    let languageName: String
    /// The real dictionaries whose style the entry should follow.
    let reference: String
    /// Lines shown directly under the headword (pronunciation, grammar facts, levels).
    let headerLines: [String]
    let sections: [Section]
    /// Language-specific editorial rules appended to the shared rules.
    let extraRules: [String]
}

// MARK: - LearnerDictionary

enum LearnerDictionary {
    // MARK: Internal

    /// Every language that has a dedicated template.
    static var supportedLanguages: Set<Language> {
        templates.reduce(into: Set<Language>()) { $0.formUnion($1.languages) }
    }

    static func template(for language: Language) -> LearnerDictTemplate? {
        templates.first { $0.languages.contains(language) }
    }

    // MARK: Query Classification

    /// Whether `text` is a single word that should get a dictionary entry instead of a plain
    /// translation. Multi-word phrases are always translated. Languages written with spaces
    /// need exactly one space-free token, whatever its inflection (Vietnamese words may span two
    /// syllables). Languages written without spaces need one content word plus only inflection,
    /// tense or aspect pieces (食べられなかった, 勉強しています, 跑了, ไปแล้ว), or a four-character
    /// idiom known to the system dictionary (画蛇添足).
    static func isDictionaryQuery(_ text: String, language: Language) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.count <= 40,
              template(for: language) != nil,
              !trimmed.contains(where: { $0.isPunctuation && !wordInternalPunctuation.contains($0) })
        else { return false }

        let words = trimmed.split(whereSeparator: \.isWhitespace)
        switch language {
        case .classicalChinese, .japanese, .simplifiedChinese, .thai, .traditionalChinese:
            guard words.count == 1, trimmed.count <= 16 else { return false }
            let pieces = tokens(trimmed, language: nlLanguage(language))
            if isSingleInflectedWord(pieces, language: language) { return true }
            // A known term split by the tokenizer is still one word when it is a four-character
            // idiom (画蛇添足); longer set phrases such as 猫の手も借りたい are translated.
            let isChinese = language != .japanese && language != .thai
            return isChinese && trimmed.count <= 4 && isSystemDictionaryTerm(trimmed)
        case .vietnamese:
            return words.count <= 2
        default:
            return words.count == 1
        }
    }

    // MARK: Prompt

    /// Builds the chat messages for one dictionary lookup.
    /// - Parameters:
    ///   - sourceLanguage: Language of the headword; selects the template.
    ///   - nativeLanguage: The app's first language. Definitions, notes and equivalents are all
    ///     written in it, whatever target language the query bar shows; a headword already in
    ///     that language gets a monolingual entry.
    static func messages(
        word: String,
        sourceLanguage: Language,
        nativeLanguage: Language
    )
        -> [ChatMessage] {
        let template = template(for: sourceLanguage) ?? englishTemplate
        let answerLanguage = nativeLanguage
        let isMonolingual = template.languages.contains(nativeLanguage)

        let system = systemPrompt(
            template: template,
            answerLanguage: answerLanguage,
            isMonolingual: isMonolingual
        )
        let user = """
        Headword: \(word.trimmingCharacters(in: .whitespacesAndNewlines))
        Headword language: \(template.languageName)

        Fill in this TEMPLATE exactly:

        \(skeleton(template: template, answerLanguage: answerLanguage))
        """

        return [
            .init(role: .system, content: system),
            .init(role: .user, content: user),
        ]
    }

    static func skeleton(template: LearnerDictTemplate, answerLanguage: Language) -> String {
        var lines = ["## ⟨headword as normally written⟩"]
        lines.append(contentsOf: template.headerLines)
        for section in template.sections {
            lines.append("")
            lines.append("### \(heading(section.heading, answerLanguage: answerLanguage))")
            lines.append(section.body)
        }
        return localizeLabels(lines.joined(separator: "\n"), answerLanguage: answerLanguage)
    }

    /// Resolves inline `«中文|English»` label tokens so field labels never vary between lookups.
    static func localizeLabels(_ text: String, answerLanguage: Language) -> String {
        let pattern = "«([^|»]*)\\|([^»]*)»"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let template = switch answerLanguage {
        case .classicalChinese, .simplifiedChinese, .traditionalChinese: "$1"
        default: "$2"
        }
        let range = NSRange(text.startIndex..., in: text)
        let resolved = regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
        if answerLanguage == .traditionalChinese {
            return resolved.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? resolved
        }
        return resolved
    }

    // MARK: Private

    private static let templates: [LearnerDictTemplate] = [
        englishTemplate,
        japaneseTemplate,
        chineseTemplate,
        koreanTemplate,
        frenchTemplate,
        germanTemplate,
        spanishTemplate,
        italianTemplate,
        portugueseTemplate,
        russianTemplate,
        arabicTemplate,
        hindiTemplate,
        bengaliTemplate,
        indonesianTemplate,
        malayTemplate,
        thaiTemplate,
        vietnameseTemplate,
    ]

    /// Auxiliary verbs and conjugation endings as split off by `NLTokenizer`, e.g.
    /// 食べ|られ|なかっ|た, 勉強|し|て|い|ます, 行か|なけれ|ば|なら|ない.
    private static let japaneseInflectionPieces: Set<String> = [
        "た", "だ", "だっ", "て", "で", "ば", "う", "よう", "ん", "ず", "ぬ",
        "ます", "ませ", "まし", "ましょ", "です", "でし", "でしょ",
        "ない", "なく", "なかっ", "なけれ", "なら", "たい", "たく", "たかっ", "たけれ",
        "れ", "れる", "られ", "られる", "せ", "せる", "させ", "させる", "さ", "し", "する", "でき", "できる",
        "い", "いる", "いた", "おり", "おる", "ある", "あっ", "あり", "ござい",
        "かっ", "く", "けれ", "そう", "ちゃ", "ちゃっ", "ちゃう", "じゃ", "じゃっ", "じゃう",
        "しまう", "しまっ", "しまい", "もらう", "もらっ", "もらい", "くれ", "くれる", "くださ", "ください",
        "あげ", "あげる", "おく", "おい", "みる", "み", "いく", "いっ", "くる", "き",
    ]

    /// 了・过・着 mark aspect on the preceding verb (跑了, 吃过, 看着).
    private static let chineseAspectParticles: Set<String> = ["了", "过", "過", "着", "著"]

    /// Tense and aspect markers around a Thai verb (ไปแล้ว, จะไป, กินอยู่).
    private static let thaiTenseMarkers: Set<String> = ["แล้ว", "อยู่", "จะ", "ได้", "กำลัง", "เคย", "ไว้"]

    /// Punctuation that can appear inside one word: e.g. "well-known", "aujourd'hui", "etc.", "Mr.".
    private static let wordInternalPunctuation: Set<Character> = ["-", "'", "’", ".", "·", "・"]

    private static func systemPrompt(
        template: LearnerDictTemplate,
        answerLanguage: Language,
        isMonolingual: Bool
    )
        -> String {
        let answer = displayName(answerLanguage)
        let headingRule = usesBuiltInHeadings(answerLanguage)
            ? "Use the headings and bold labels exactly as written in the TEMPLATE."
            : "Translate each TEMPLATE heading and bold label into \(answer) and use that same wording every time."

        var rules = [
            "Output ONLY the Markdown entry. No preface, no closing remarks, no code fences.",
            "Follow the TEMPLATE exactly: same headings, same order, same line layout and table columns. Never add, rename, merge or drop a heading. \(headingRule)",
            "Replace every ⟨…⟩ placeholder with real content. Never output the characters ⟨ or ⟩.",
            "If a field or a whole section does not apply to this headword (for example a conjugation table for a noun), write — in its place; keep the heading.",
            isMonolingual
                ? "This is a monolingual entry: write everything in \(answer). Omit the ⟨equivalents⟩ fields and the — translations after examples."
                :
                "Write definitions, explanations, notes and equivalents (translation words) in \(answer). Write example sentences in \(template.languageName) followed by their \(answer) translation.",
            "Order senses from most to least common; at most 6 senses, 1–2 short natural examples each, at learner level.",
            "Grammar facts (pronunciation, gender, inflection, levels) must be accurate. When unsure, write — instead of guessing.",
            "Treat the whole input as one headword. If it is an inflected form, use its dictionary form as the headword and name the inflection in the first sense. If it looks misspelled, use the most likely intended word.",
        ]
        rules.append(contentsOf: template.extraRules)

        let numbered = rules.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        return """
        You are the chief editor of a learner's dictionary of \(template.languageName), written for learners whose native language is \(answer). Your entries follow the style and rigor of \(template.reference): fixed layout, complete and reliable information, clear for learners.

        Rules:
        \(numbered)
        """
    }

    private static func heading(_ heading: LearnerDictTemplate.Heading, answerLanguage: Language) -> String {
        switch answerLanguage {
        case .classicalChinese, .simplifiedChinese:
            heading.zh
        case .traditionalChinese:
            heading.zh.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? heading.zh
        default:
            heading.en
        }
    }

    private static func usesBuiltInHeadings(_ language: Language) -> Bool {
        [.simplifiedChinese, .traditionalChinese, .classicalChinese, .english].contains(language)
    }

    private static func displayName(_ language: Language) -> String {
        switch language {
        case .simplifiedChinese: "Simplified Chinese (简体中文)"
        case .traditionalChinese: "Traditional Chinese (繁體中文)"
        case .classicalChinese: "Simplified Chinese (简体中文)"
        case .brazilianPortuguese: "Brazilian Portuguese"
        default: language.rawValue.replacingOccurrences(of: "-", with: " ")
        }
    }

    private static func tokens(_ text: String, language: NLLanguage) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(language)
        return tokenizer.tokens(for: text.startIndex ..< text.endIndex).map { String(text[$0]) }
    }

    /// Whether the tokens form one content word followed (or, in Thai, also preceded) only by
    /// pieces that inflect it. Linking particles such as に・を・の・も are deliberately absent,
    /// so 日本に行く and 猫の手も借りたい stay phrases.
    private static func isSingleInflectedWord(_ tokens: [String], language: Language) -> Bool {
        guard let first = tokens.first else { return false }
        switch language {
        case .japanese:
            return !japaneseInflectionPieces.contains(first)
                && tokens.dropFirst().allSatisfy(japaneseInflectionPieces.contains)
        case .thai:
            return tokens.filter { !thaiTenseMarkers.contains($0) }.count == 1
        default:
            return tokens.count == 1
                || (tokens.count == 2 && chineseAspectParticles.contains(tokens[1]))
        }
    }

    private static func nlLanguage(_ language: Language) -> NLLanguage {
        switch language {
        case .japanese: .japanese
        case .thai: .thai
        case .traditionalChinese: .traditionalChinese
        default: .simplifiedChinese
        }
    }

    /// Whether a macOS system dictionary recognises the whole string as one term.
    private static func isSystemDictionaryTerm(_ text: String) -> Bool {
        let length = (text as NSString).length
        let range = DCSGetTermRangeInString(nil, text as CFString, 0)
        return range.location == 0 && range.length == length
    }
}

// MARK: - Shared Sections

extension LearnerDictionary {
    typealias Section = LearnerDictTemplate.Section
    typealias Heading = LearnerDictTemplate.Heading

    static func sensesSection(posHint: String) -> Section {
        Section(
            heading: Heading(zh: "释义", en: "Definitions"),
            body: """
            1. **⟨part of speech: \(posHint)⟩** ⟨definition⟩；⟨equivalents⟩
               - ⟨example sentence⟩ — ⟨translation⟩
               - ⟨example sentence⟩ — ⟨translation⟩
            2. **⟨part of speech⟩** ⟨definition⟩；⟨equivalents⟩
               - ⟨example sentence⟩ — ⟨translation⟩
            """
        )
    }

    static func collocationsSection(_ hint: String) -> Section {
        Section(
            heading: Heading(zh: "常用搭配与短语", en: "Collocations & Phrases"),
            body: """
            - **⟨\(hint)⟩** ⟨meaning⟩
            - **⟨\(hint)⟩** ⟨meaning⟩
            - **⟨\(hint)⟩** ⟨meaning⟩
            """
        )
    }

    static var synonymsSection: Section {
        Section(
            heading: Heading(zh: "近义词与反义词", en: "Synonyms & Antonyms"),
            body: """
            - **«近义|Synonyms»** ⟨synonym⟩, ⟨synonym⟩, ⟨synonym⟩
            - **«反义|Antonyms»** ⟨antonym⟩, ⟨antonym⟩
            - **«辨析|Distinction»** ⟨how the headword differs from its closest synonym, one or two sentences⟩
            """
        )
    }

    static func notesSection(_ focus: String) -> Section {
        Section(
            heading: Heading(zh: "学习提示", en: "Learner Notes"),
            body: """
            - ⟨\(focus)⟩
            - ⟨another common learner mistake or usage tip⟩
            """
        )
    }

    static func table(_ heading: Heading, _ markdownTable: String) -> Section {
        Section(heading: heading, body: markdownTable)
    }
}
