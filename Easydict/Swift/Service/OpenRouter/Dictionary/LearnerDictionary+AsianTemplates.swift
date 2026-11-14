//
//  LearnerDictionary+AsianTemplates.swift
//  AI-Dict
//
//  Templates for Chinese, Japanese, Korean, Thai, Vietnamese, Indonesian and Malay headwords.
//

import Foundation

extension LearnerDictionary {
    // MARK: Chinese — 现代汉语词典 / Pleco

    static let chineseTemplate = LearnerDictTemplate(
        languages: [.simplifiedChinese, .traditionalChinese, .classicalChinese],
        languageName: "Chinese (Mandarin)",
        reference: "现代汉语词典 (Contemporary Chinese Dictionary), 现代汉语规范词典 and the Pleco learner dictionary",
        headerLines: [
            "**«拼音|Pinyin»** ⟨pinyin with tone marks, syllables separated⟩ · **«简/繁|Simp./Trad.»** ⟨simplified⟩ / ⟨traditional⟩",
            "**HSK** ⟨HSK 3.0 level 1–9, or —⟩ · **«结构|Structure»** ⟨word formation, e.g. 动宾式 / 偏正式 / 联合式, or —⟩",
        ],
        sections: [
            sensesSection(posHint: "名 / 动 / 形 / 副 / 量 / 介 / 连 / 助 / 叹 …"),
            Section(
                heading: Heading(zh: "量词", en: "Measure Words"),
                body: "- ⟨measure word(s) used with this noun, with one example phrase each, or —⟩"
            ),
            collocationsSection("common word / collocation built with the headword"),
            Section(
                heading: Heading(zh: "成语·俗语", en: "Idioms & Sayings"),
                body: """
                - **⟨idiom or saying containing the headword⟩** ⟨meaning⟩（«出处|Source»：⟨classical source, or —⟩）
                - **⟨idiom or saying⟩** ⟨meaning⟩
                """
            ),
            synonymsSection,
            notesSection("tone sandhi, easily confused characters, register (书面/口语) or usage pitfalls"),
        ],
        extraRules: [
            "For a 成语, explain the literal meaning, the figurative meaning and the origin in the definitions.",
            "Mark tone changes (一、不、third-tone sandhi) where relevant in the notes, but write citation tones in Pinyin.",
        ]
    )

    // MARK: Japanese — MOJi辞書 / 大辞林

    static let japaneseTemplate = LearnerDictTemplate(
        languages: [.japanese],
        languageName: "Japanese",
        reference: "MOJi辞書, 大辞林 and the NHK日本語発音アクセント辞典",
        headerLines: [
            "【⟨reading in hiragana/katakana⟩】⟨headword in standard kanji/kana spelling⟩ ⟨pitch accent number in circled digits, e.g. ⓪ ①⟩",
            "**«罗马字|Romaji»** ⟨Hepburn romaji⟩ · **JLPT** ⟨N5–N1, or —⟩ · **«词性|Type»** ⟨detailed part of speech, e.g. 自動詞・五段 / 他動詞・一段 / 名詞・サ変 / イ形容詞 / ナ形容詞⟩",
            "**«其他写法|Other spellings»** ⟨alternative kanji/kana spellings, or —⟩ · **«语种|Origin»** ⟨和語 / 漢語 / 外来語（source language）/ 和製英語⟩",
        ],
        sections: [
            sensesSection(posHint: "〔名〕〔自動・五段〕〔他動・一段〕〔イ形〕〔ナ形〕〔副〕…"),
            table(
                Heading(zh: "活用", en: "Conjugation"),
                """
                | ⟨form name⟩ | ⟨conjugated form⟩ |
                |---|---|
                | 辞書形 | ⟨…⟩ |
                | ます形 | ⟨…⟩ |
                | て形 | ⟨…⟩ |
                | た形 | ⟨…⟩ |
                | ない形 | ⟨…⟩ |
                | 可能形 | ⟨…⟩ |
                | 受身形 | ⟨…⟩ |
                | 使役形 | ⟨…⟩ |
                | 意志形 | ⟨…⟩ |
                | 仮定形（ば） | ⟨…⟩ |
                | 命令形 | ⟨…⟩ |
                (For イ/ナ adjectives use: 現在・否定・過去・過去否定・て形・副詞形. For nouns and other uninflected words replace the whole table with —)
                """
            ),
            collocationsSection("set phrase, collocation or 慣用句 with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "敬语与语体", en: "Politeness & Register"),
                body: "- ⟨尊敬語 / 謙譲語 / 丁寧語 forms if any, and whether the word is spoken, written, formal, slang or gendered; otherwise —⟩"
            ),
            notesSection("kanji vs kana usage, particle choice (を/が/に), or common learner mistakes"),
        ],
        extraRules: [
            "Example sentences are natural Japanese; add the reading of difficult kanji in parentheses after the word.",
            "Pitch accent follows the Tokyo standard (NHK). If uncertain, write —.",
        ]
    )

    // MARK: Korean — Naver 국어사전 / 표준국어대사전

    static let koreanTemplate = LearnerDictTemplate(
        languages: [.korean],
        languageName: "Korean",
        reference: "the Naver Korean dictionary, 표준국어대사전 and 한국어기초사전 (Basic Korean Dictionary for learners)",
        headerLines: [
            "**«发音|Pronunciation»** [⟨actual pronunciation in Hangul after sound changes⟩] ⟨Revised Romanization⟩",
            "**«汉字|Hanja»** ⟨hanja for Sino-Korean words, or 固有词 / 外来语（source）⟩ · **TOPIK** ⟨初级 / 中级 / 高级, or —⟩ · **«词性|POS»** ⟨명사 / 동사 / 형용사 / 부사 …⟩",
        ],
        sections: [
            sensesSection(posHint: "명사 / 동사 / 형용사 / 부사 / 조사 / 감탄사 …"),
            table(
                Heading(zh: "活用", en: "Conjugation"),
                """
                | ⟨form⟩ | ⟨conjugated form⟩ |
                |---|---|
                | 기본형 | ⟨…⟩ |
                | -아요/어요 | ⟨…⟩ |
                | -ㅂ니다/습니다 | ⟨…⟩ |
                | «过去|Past» -았/었어요 | ⟨…⟩ |
                | «将来|Future» -(으)ㄹ 거예요 | ⟨…⟩ |
                | -고 | ⟨…⟩ |
                | -아서/어서 | ⟨…⟩ |
                | -(으)면 | ⟨…⟩ |
                | «冠形|Adnominal» -(으)ㄴ/는 | ⟨…⟩ |
                (For nouns and other uninflected words replace the whole table with —. Mention irregular conjugation (ㅂ/ㄷ/ㅅ/르/ㅎ 불규칙) in the notes.)
                """
            ),
            collocationsSection("collocation or expression with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "敬语与语体", en: "Honorifics & Speech Level"),
                body: "- ⟨honorific (높임말) or humble counterparts, e.g. 먹다→드시다/잡수시다, and register; otherwise —⟩"
            ),
            notesSection("sound changes, irregular conjugation, or confusion with similar words"),
        ],
        extraRules: []
    )

    // MARK: Thai — Longdo Dict / Thai2English

    static let thaiTemplate = LearnerDictTemplate(
        languages: [.thai],
        languageName: "Thai",
        reference: "Longdo Dict, Thai2English and the Royal Institute Dictionary (พจนานุกรม ฉบับราชบัณฑิตยสถาน)",
        headerLines: [
            "**«转写|Romanization»** ⟨tone-marked transliteration, e.g. khàap-khun⟩ · **«RTGS|RTGS»** ⟨RTGS spelling⟩",
            "**«音节|Syllables»** ⟨each syllable: Thai spelling – consonant class (中/高/低 or mid/high/low) – live/dead – tone⟩",
            "**«词性|POS»** ⟨part of speech⟩ · **«来源|Origin»** ⟨native Thai / Pali-Sanskrit / Khmer / Chinese / English loan⟩",
        ],
        sections: [
            sensesSection(posHint: "n. / v. / adj. / adv. / clf. / part. …"),
            Section(
                heading: Heading(zh: "量词", en: "Classifier"),
                body: "- ⟨ลักษณนาม used with this noun, with an example such as หมา 2 ตัว, or —⟩"
            ),
            collocationsSection("common compound or expression with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "礼貌与语体", en: "Politeness & Register"),
                body: "- ⟨polite particles (ครับ/ค่ะ), formal/royal (ราชาศัพท์) or colloquial equivalents; otherwise —⟩"
            ),
            notesSection("tone rules, silent letters, or easily confused words"),
        ],
        extraRules: [
            "Give tone marks in transliteration (à á â ǎ a). Examples are written in Thai script followed by transliteration in parentheses and then the translation.",
        ]
    )

    // MARK: Vietnamese — Từ điển tiếng Việt (Hoàng Phê) / Vdict

    static let vietnameseTemplate = LearnerDictTemplate(
        languages: [.vietnamese],
        languageName: "Vietnamese",
        reference: "Từ điển tiếng Việt (Hoàng Phê, Vietnam Institute of Linguistics), Vdict and the Hồ Ngọc Đức dictionary",
        headerLines: [
            "**«发音|Pronunciation»** «北|Hanoi» /⟨IPA⟩/ · «南|Saigon» /⟨IPA⟩/",
            "**«声调|Tones»** ⟨tone of each syllable: ngang / huyền / sắc / hỏi / ngã / nặng⟩ · **«词性|POS»** ⟨danh từ / động từ / tính từ …⟩",
            "**«汉越|Sino-Vietnamese»** ⟨Hán tự of each syllable for Sino-Vietnamese words, or 纯越词 / native word⟩",
        ],
        sections: [
            sensesSection(posHint: "danh từ / động từ / tính từ / phó từ / loại từ …"),
            Section(
                heading: Heading(zh: "类别词", en: "Classifier"),
                body: "- ⟨loại từ used with this noun (cái, con, chiếc, quyển …) with an example, or —⟩"
            ),
            collocationsSection("common compound or expression with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "南北差异", en: "North–South Differences"),
                body: "- ⟨differences in pronunciation or vocabulary between Hanoi and Saigon usage; otherwise —⟩"
            ),
            notesSection("tone or spelling confusion, or usage pitfalls"),
        ],
        extraRules: []
    )

    // MARK: Indonesian — KBBI

    static let indonesianTemplate = LearnerDictTemplate(
        languages: [.indonesian],
        languageName: "Indonesian",
        reference: "KBBI (Kamus Besar Bahasa Indonesia) and the Kamus Indonesia–Inggris by Echols & Shadily",
        headerLines: [
            "/⟨IPA⟩/ · **«词根|Root»** ⟨kata dasar⟩ · **«词性|POS»** ⟨n / v / a / adv / p …⟩",
            "**«语域|Register»** ⟨baku / tidak baku / cakapan / regional⟩ · **«来源|Origin»** ⟨native / Sanskrit / Arabic / Dutch / Portuguese / English …⟩",
        ],
        sections: [
            sensesSection(posHint: "n / v / a / adv / num / p …"),
            table(
                Heading(zh: "派生词", en: "Derived Forms"),
                """
                | «词缀|Affix» | «词形|Form» | «意思|Meaning» |
                |---|---|---|
                | ⟨affix, e.g. me-, di-, ber-, ter-, pe-, pe-an, ke-an, -kan, -i, reduplication⟩ | ⟨derived word⟩ | ⟨meaning⟩ |
                (List the 3–6 most common derived forms of the root.)
                """
            ),
            collocationsSection("common collocation or expression with the headword"),
            synonymsSection,
            notesSection("affix choice, baku vs. colloquial spelling, or false friends with Malay"),
        ],
        extraRules: []
    )

    // MARK: Malay — Kamus Dewan

    static let malayTemplate = LearnerDictTemplate(
        languages: [.malay],
        languageName: "Malay",
        reference: "Kamus Dewan (Dewan Bahasa dan Pustaka) and Pusat Rujukan Persuratan Melayu (PRPM)",
        headerLines: [
            "/⟨IPA⟩/ · **«词根|Root»** ⟨kata dasar⟩ · **«词性|POS»** ⟨kata nama / kata kerja / kata adjektif …⟩",
            "**«爪夷文|Jawi»** ⟨Jawi spelling, or —⟩ · **«来源|Origin»** ⟨native / Sanskrit / Arabic / English …⟩",
        ],
        sections: [
            sensesSection(posHint: "kata nama / kata kerja / kata adjektif / kata adverba …"),
            table(
                Heading(zh: "派生词", en: "Derived Forms"),
                """
                | «词缀|Affix» | «词形|Form» | «意思|Meaning» |
                |---|---|---|
                | ⟨affix, e.g. me-, di-, ber-, ter-, pe-, pe-an, ke-an, -kan, -i, reduplication⟩ | ⟨derived word⟩ | ⟨meaning⟩ |
                (List the 3–6 most common derived forms of the root.)
                """
            ),
            collocationsSection("common collocation or peribahasa with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "与印尼语差异", en: "Differences from Indonesian"),
                body: "- ⟨spelling, meaning or usage differences from Indonesian; otherwise —⟩"
            ),
            notesSection("affix choice, formal vs. colloquial usage, or false friends"),
        ],
        extraRules: []
    )
}
