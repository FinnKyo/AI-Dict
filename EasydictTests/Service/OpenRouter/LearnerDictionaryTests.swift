//
//  LearnerDictionaryTests.swift
//  EasydictTests
//
//  Covers word/phrase detection, template coverage and prompt layout for the learner dictionary.
//

import Testing

@testable import Easydict

// MARK: - LearnerDictionaryTests

@Suite("LearnerDictionary", .tags(.unit))
struct LearnerDictionaryTests {
    /// The 17 languages AI-Dict promises dedicated dictionary templates for.
    static let requiredLanguages: [Language] = [
        .simplifiedChinese, .japanese, .english, .korean, .french, .italian, .german,
        .spanish, .portuguese, .russian, .indonesian, .thai, .hindi, .malay,
        .vietnamese, .arabic, .bengali,
    ]

    @Test("every supported language has its own template", arguments: requiredLanguages)
    func everyLanguageHasTemplate(language: Language) throws {
        let template = try #require(LearnerDictionary.template(for: language))
        #expect(!template.sections.isEmpty)
        #expect(!template.headerLines.isEmpty)
        #expect(!template.reference.isEmpty)
    }

    @Test("templates are not shared between unrelated languages")
    func templatesAreDistinct() {
        let names = Self.requiredLanguages.compactMap { LearnerDictionary.template(for: $0)?.languageName }
        #expect(Set(names).count == Self.requiredLanguages.count)
    }

    @Test(
        "single words are dictionary queries",
        arguments: [
            ("run", Language.english),
            ("  run\n", .english),
            ("well-known", .english),
            ("etc.", .english),
            ("aujourd'hui", .french),
            ("食べる", .japanese),
            ("画蛇添足", .simplifiedChinese),
            ("苹果", .simplifiedChinese),
            ("사랑하다", .korean),
            ("Schadenfreude", .german),
            ("ขอบคุณ", .thai),
            ("كتاب", .arabic),
            ("किताब", .hindi),
            ("বই", .bengali),
            ("makan", .indonesian),
            ("cảm ơn", .vietnamese),
            ("говорить", .russian),
        ]
    )
    func detectsDictionaryQueries(text: String, language: Language) {
        #expect(LearnerDictionary.isDictionaryQuery(text, language: language))
    }

    @Test(
        "inflected and tensed forms of one word are dictionary queries",
        arguments: [
            ("ran", Language.english),
            ("running", .english),
            ("children", .english),
            ("mangeons", .french),
            ("gegangen", .german),
            ("hablé", .spanish),
            ("говорил", .russian),
            ("먹었어요", .korean),
            ("食べた", .japanese),
            ("食べられなかった", .japanese),
            ("勉強しています", .japanese),
            ("見せてもらった", .japanese),
            ("行かなければならない", .japanese),
            ("来ませんでした", .japanese),
            ("静かだった", .japanese),
            ("忘れちゃった", .japanese),
            ("跑了", .simplifiedChinese),
            ("吃过", .simplifiedChinese),
            ("看着", .simplifiedChinese),
            ("ไปแล้ว", .thai),
            ("จะไป", .thai),
        ]
    )
    func detectsInflectedWords(text: String, language: Language) {
        #expect(LearnerDictionary.isDictionaryQuery(text, language: language))
    }

    @Test(
        "phrases and sentences are not dictionary queries",
        arguments: [
            ("look forward to", Language.english),
            ("ice cream", .english),
            ("avoir besoin de", .french),
            ("猫の手も借りたい", .japanese),
            ("日本に行く", .japanese),
            ("苹果手机", .simplifiedChinese),
            ("我爱你", .simplifiedChinese),
            ("吃了饭", .simplifiedChinese),
            ("本を読む", .japanese),
            ("私は", .japanese),
            ("寝る前に", .japanese),
            ("ไปโรงเรียน", .thai),
            ("사랑해 요", .korean),
            ("I would like to run home now", .english),
            ("Hello, world", .english),
            ("今日はいい天気ですね。", .japanese),
            ("我今天很高兴，因为考试通过了", .simplifiedChinese),
            ("Ich habe heute keine Zeit für dich", .german),
            ("Where are you going?", .english),
            ("line one\nline two", .english),
        ]
    )
    func rejectsSentences(text: String, language: Language) {
        #expect(!LearnerDictionary.isDictionaryQuery(text, language: language))
    }

    @Test("languages without a template fall back to translation")
    func unsupportedLanguageIsNotDictionary() {
        #expect(!LearnerDictionary.isDictionaryQuery("hond", language: .dutch))
    }

    @Test("skeleton localises headings and labels for Chinese learners")
    func chineseSkeleton() throws {
        let template = try #require(LearnerDictionary.template(for: .japanese))
        let skeleton = LearnerDictionary.skeleton(template: template, answerLanguage: .simplifiedChinese)

        #expect(skeleton.contains("### 释义"))
        #expect(skeleton.contains("### 活用"))
        #expect(skeleton.contains("**罗马字**"))
        #expect(!skeleton.contains("«"))
        #expect(!skeleton.contains("Romaji"))
    }

    @Test("skeleton uses English labels for English-speaking learners")
    func englishSkeleton() throws {
        let template = try #require(LearnerDictionary.template(for: .french))
        let skeleton = LearnerDictionary.skeleton(template: template, answerLanguage: .english)

        #expect(skeleton.contains("### Definitions"))
        #expect(skeleton.contains("### Conjugation"))
        #expect(!skeleton.contains("«"))
        #expect(!skeleton.contains("释义"))
    }

    @Test("traditional Chinese learners get traditional labels")
    func traditionalSkeleton() throws {
        let template = try #require(LearnerDictionary.template(for: .english))
        let skeleton = LearnerDictionary.skeleton(template: template, answerLanguage: .traditionalChinese)

        #expect(skeleton.contains("### 釋義"))
        #expect(skeleton.contains("### 詞形變化"))
    }

    @Test("entries are written entirely in the first language")
    func messageLanguages() throws {
        let messages = LearnerDictionary.messages(
            word: "Haus", sourceLanguage: .german, nativeLanguage: .simplifiedChinese
        )
        let system = try #require(messages.first { $0.role == .system }?.content)
        let user = try #require(messages.first { $0.role == .user }?.content)

        #expect(system.contains("Duden"))
        #expect(system.contains("native language is Simplified Chinese"))
        #expect(system.contains("equivalents (translation words) in Simplified Chinese"))
        #expect(user.contains("Headword: Haus"))
        #expect(user.contains("### 支配"))
    }

    @Test("a first-language headword gets a monolingual entry")
    func monolingualEntry() throws {
        let messages = LearnerDictionary.messages(
            word: "苹果", sourceLanguage: .simplifiedChinese, nativeLanguage: .traditionalChinese
        )
        let system = try #require(messages.first { $0.role == .system }?.content)
        #expect(system.contains("monolingual entry"))
        #expect(!system.contains("English"))
    }
}

// MARK: - OpenRouterAvailabilityTests

@Suite("OpenRouterAvailability", .tags(.unit))
struct OpenRouterAvailabilityTests {
    // MARK: Internal

    @Test("healthy endpoints with high uptime are available")
    func available() {
        let (state, uptime) = OpenRouterAvailability.from(endpoints: [endpoint(status: 0, uptime30m: 99, uptime1d: 98)])
        #expect(state == .available)
        #expect(uptime == 99)
    }

    @Test("a zero 30-minute uptime falls back to the daily value")
    func fallsBackToDaily() {
        let (state, uptime) = OpenRouterAvailability.from(endpoints: [endpoint(status: 0, uptime30m: 0, uptime1d: 80)])
        #expect(state == .unstable)
        #expect(uptime == 80)
    }

    @Test("negative status on every endpoint means down")
    func down() {
        let (state, _) = OpenRouterAvailability.from(endpoints: [endpoint(status: -2, uptime30m: 99, uptime1d: 99)])
        #expect(state == .down)
    }

    @Test("no endpoints means down; no uptime data means unknown")
    func emptyAndUnknown() {
        #expect(OpenRouterAvailability.from(endpoints: []).0 == .down)
        #expect(OpenRouterAvailability.from(endpoints: [endpoint(status: 0, uptime30m: nil, uptime1d: nil)])
            .0 == .unknown)
    }

    // MARK: Private

    private func endpoint(status: Int?, uptime30m: Double?, uptime1d: Double?) -> OpenRouterEndpoint {
        OpenRouterEndpoint(providerName: "P", status: status, uptimeLast30m: uptime30m, uptimeLast1d: uptime1d)
    }
}
