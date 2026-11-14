//
//  LearnerDictionary+WesternTemplates.swift
//  AI-Dict
//
//  Templates for English, French, German, Spanish, Italian, Portuguese, Russian,
//  Arabic, Hindi and Bengali headwords.
//

import Foundation

extension LearnerDictionary {
    // MARK: English — 有道词典 / Oxford Advanced Learner's Dictionary

    static let englishTemplate = LearnerDictTemplate(
        languages: [.english],
        languageName: "English",
        reference: "the Youdao dictionary (有道词典), the Oxford Advanced Learner's Dictionary and the Collins COBUILD dictionary",
        headerLines: [
            "**«英|UK»** /⟨British IPA⟩/ · **«美|US»** /⟨American IPA⟩/",
            "**CEFR** ⟨A1–C2, or —⟩ · **«考试|Exams»** ⟨which of 中考 / 高考 / CET-4 / CET-6 / 考研 / IELTS / TOEFL / GRE include this word, or —⟩ · **«词频|Frequency»** ⟨★ to ★★★★★⟩",
        ],
        sections: [
            sensesSection(posHint: "n. [C]/[U] · v. [T]/[I] · adj. · adv. · prep. · conj. · phr. v. …"),
            table(
                Heading(zh: "词形变化", en: "Word Forms"),
                """
                | «形式|Form» | «词形|Word» |
                |---|---|
                | ⟨applicable form: plural / third person singular / present participle / past tense / past participle / comparative / superlative⟩ | ⟨word⟩ |
                (Include only the forms that apply, marking irregular forms with *. Uninflected words: replace the whole table with —)
                """
            ),
            collocationsSection("phrasal verb, idiom or collocation with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "词源", en: "Etymology"),
                body: "- ⟨short origin of the word in one or two sentences, with a memory tip if helpful⟩"
            ),
            notesSection("countability, preposition choice, British vs. American usage, or common learner errors"),
        ],
        extraRules: []
    )

    // MARK: French — Le Petit Robert / Larousse / 欧路法汉

    static let frenchTemplate = LearnerDictTemplate(
        languages: [.french],
        languageName: "French",
        reference: "Le Petit Robert, the Larousse dictionary and the Eudic French dictionary (欧路法语助手)",
        headerLines: [
            "/⟨IPA⟩/ · **«词性|POS»** ⟨n.m. / n.f. / v.t. / v.i. / v.pr. / adj. / adv. …⟩ · **CEFR** ⟨A1–C2, or —⟩",
            "**«阴阳性·复数|Gender & Plural»** ⟨feminine form and plural form, or —⟩",
        ],
        sections: [
            sensesSection(
                posHint: "n.m. / n.f. / v.t. / v.i. / v.pr. / adj. / adv. …, with register labels fam. / soutenu / vieilli when relevant"
            ),
            table(
                Heading(zh: "动词变位", en: "Conjugation"),
                """
                **«变位组|Group»** ⟨1er / 2e / 3e groupe⟩ · **«助动词|Auxiliary»** ⟨avoir / être⟩ · **«过去分词|Past participle»** ⟨…⟩ · **«现在分词|Present participle»** ⟨…⟩

                | | «直陈式现在时|Présent» | «复合过去时|Passé composé» | «未完成过去时|Imparfait» | «简单将来时|Futur simple» |
                |---|---|---|---|---|
                | je | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | tu | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | il/elle | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | nous | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | vous | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | ils/elles | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                (Non-verbs: replace the whole section body with —)
                """
            ),
            collocationsSection("expression, locution or collocation with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "发音提示", en: "Pronunciation Notes"),
                body: "- ⟨liaison, élision, h aspiré, silent letters or nasal vowels relevant to this word; otherwise —⟩"
            ),
            notesSection("faux amis, gender pitfalls, or preposition choice"),
        ],
        extraRules: []
    )

    // MARK: German — Duden / PONS / Langenscheidt

    static let germanTemplate = LearnerDictTemplate(
        languages: [.german],
        languageName: "German",
        reference: "Duden, PONS and Langenscheidt Großwörterbuch Deutsch als Fremdsprache",
        headerLines: [
            "/⟨IPA⟩/ · **«词性|POS»** ⟨Nomen / Verb / Adjektiv / Adverb …⟩ · **CEFR** ⟨A1–C2, or —⟩",
            "**«名词|Noun»** ⟨der/die/das + headword, genitive singular, plural (e.g. der Hund, -(e)s, -e), or —⟩",
            "**«动词|Verb»** ⟨Infinitiv – Präteritum – Partizip II, hat/ist; trennbar/untrennbar; stark/schwach/gemischt, or —⟩",
        ],
        sections: [
            sensesSection(posHint: "Nomen (m/f/n) / Verb (tr./intr./refl.) / Adj. / Adv. …"),
            table(
                Heading(zh: "变化表", en: "Inflection"),
                """
                | | «现在时|Präsens» | «过去时|Präteritum» | «第二虚拟式|Konjunktiv II» |
                |---|---|---|---|
                | ich | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | du | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | er/sie/es | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | wir | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | ihr | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | sie/Sie | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                (For nouns use a table with rows Nominativ / Genitiv / Dativ / Akkusativ and columns Singular / Plural. For adjectives give Positiv / Komparativ / Superlativ.)
                """
            ),
            Section(
                heading: Heading(zh: "支配", en: "Government"),
                body: "- ⟨case or preposition the word governs, e.g. + Akk., warten auf + Akk.; otherwise —⟩"
            ),
            collocationsSection("Redewendung or collocation with the headword"),
            synonymsSection,
            notesSection("separable prefixes, word order, or case errors"),
        ],
        extraRules: []
    )

    // MARK: Spanish — RAE (DLE) / SpanishDict

    static let spanishTemplate = LearnerDictTemplate(
        languages: [.spanish],
        languageName: "Spanish",
        reference: "the Diccionario de la lengua española (RAE/ASALE) and SpanishDict",
        headerLines: [
            "/⟨IPA⟩/ · **«词性|POS»** ⟨m. / f. / v. tr. / v. intr. / v. prnl. / adj. / adv. …⟩ · **CEFR** ⟨A1–C2, or —⟩",
            "**«阴阳性·复数|Gender & Plural»** ⟨feminine and plural forms, or —⟩",
        ],
        sections: [
            sensesSection(
                posHint: "m. / f. / v. tr. / v. intr. / v. prnl. / adj. …, with region labels Esp. / Amér. / Méx. when relevant"
            ),
            table(
                Heading(zh: "动词变位", en: "Conjugation"),
                """
                **«过去分词|Participio»** ⟨…⟩ · **«副动词|Gerundio»** ⟨…⟩ · **«变位类型|Pattern»** ⟨regular -ar/-er/-ir or irregular (stem change e→ie, etc.)⟩

                | | «现在时|Presente» | «简单过去时|Pretérito indefinido» | «过去未完成时|Imperfecto» | «将来时|Futuro» | «虚拟式现在时|Subjuntivo presente» |
                |---|---|---|---|---|---|
                | yo | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | tú | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | él/ella/usted | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | nosotros | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | vosotros | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | ellos/ustedes | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                (Non-verbs: replace the whole section body with —)
                """
            ),
            collocationsSection("expression or collocation with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "地区差异", en: "Regional Usage"),
                body: "- ⟨differences between Spain and Latin America in meaning, word choice or pronunciation; otherwise —⟩"
            ),
            notesSection("ser/estar, por/para, accent marks or false friends"),
        ],
        extraRules: []
    )

    // MARK: Italian — Treccani / Zanichelli (Lo Zingarelli)

    static let italianTemplate = LearnerDictTemplate(
        languages: [.italian],
        languageName: "Italian",
        reference: "the Treccani Vocabolario and Lo Zingarelli (Zanichelli)",
        headerLines: [
            "/⟨IPA⟩/ · **«重音|Stress»** ⟨headword with the stressed vowel marked, e.g. pàrlo⟩ · **«词性|POS»** ⟨s.m. / s.f. / v.tr. / v.intr. / agg. …⟩",
            "**«阴阳性·复数|Gender & Plural»** ⟨feminine and plural forms, or —⟩ · **CEFR** ⟨A1–C2, or —⟩",
        ],
        sections: [
            sensesSection(posHint: "s.m. / s.f. / v.tr. / v.intr. / v.rifl. / agg. / avv. …"),
            table(
                Heading(zh: "动词变位", en: "Conjugation"),
                """
                **«助动词|Auxiliary»** ⟨essere / avere⟩ · **«过去分词|Participio passato»** ⟨…⟩ · **«副动词|Gerundio»** ⟨…⟩

                | | «现在时|Presente» | «近过去时|Passato prossimo» | «未完成过去时|Imperfetto» | «将来时|Futuro semplice» | «虚拟式现在时|Congiuntivo presente» |
                |---|---|---|---|---|---|
                | io | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | tu | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | lui/lei | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | noi | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | voi | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | loro | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                (Non-verbs: replace the whole section body with —)
                """
            ),
            collocationsSection("modo di dire or collocation with the headword"),
            synonymsSection,
            notesSection("double consonants, auxiliary choice, or false friends"),
        ],
        extraRules: []
    )

    // MARK: Portuguese — Priberam / Michaelis

    static let portugueseTemplate = LearnerDictTemplate(
        languages: [.portuguese, .brazilianPortuguese],
        languageName: "Portuguese",
        reference: "the Priberam dictionary, Michaelis and the Dicionário Houaiss",
        headerLines: [
            "**«巴葡|BR»** /⟨Brazilian IPA⟩/ · **«欧葡|PT»** /⟨European IPA⟩/",
            "**«词性|POS»** ⟨s.m. / s.f. / v.t. / v.i. / v.pron. / adj. …⟩ · **«阴阳性·复数|Gender & Plural»** ⟨feminine and plural forms, or —⟩",
        ],
        sections: [
            sensesSection(
                posHint: "s.m. / s.f. / v.t. / v.i. / v.pron. / adj. / adv. …, with labels Bras. / Port. when relevant"
            ),
            table(
                Heading(zh: "动词变位", en: "Conjugation"),
                """
                **«过去分词|Particípio»** ⟨…⟩ · **«副动词|Gerúndio»** ⟨…⟩

                | | «现在时|Presente» | «完成过去时|Pretérito perfeito» | «未完成过去时|Imperfeito» | «将来时|Futuro» | «虚拟式现在时|Subjuntivo presente» |
                |---|---|---|---|---|---|
                | eu | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | tu | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | ele/ela/você | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | nós | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                | eles/elas/vocês | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ | ⟨…⟩ |
                (Non-verbs: replace the whole section body with —)
                """
            ),
            collocationsSection("expression or collocation with the headword"),
            synonymsSection,
            Section(
                heading: Heading(zh: "巴葡与欧葡差异", en: "Brazil vs. Portugal"),
                body: "- ⟨differences in meaning, word choice, spelling or pronunciation; otherwise —⟩"
            ),
            notesSection("nasal vowels, false friends, or pronoun placement"),
        ],
        extraRules: []
    )

    // MARK: Russian — Ожегов / Большой русско-китайский словарь

    static let russianTemplate = LearnerDictTemplate(
        languages: [.russian],
        languageName: "Russian",
        reference: "the Ozhegov dictionary (Толковый словарь Ожегова), the Большой русско-китайский словарь and Wiktionary inflection tables",
        headerLines: [
            "⟨headword with stress mark, e.g. говори́ть⟩ /⟨IPA⟩/ · **«词性|POS»** ⟨сущ. / глаг. / прил. / нареч. …⟩ · **ТРКИ** ⟨A1–C2, or —⟩",
            "**«性|Gender»** ⟨м. / ж. / ср., animate or inanimate, or —⟩ · **«体|Aspect»** ⟨несов. / сов. and its aspect pair, or —⟩",
        ],
        sections: [
            sensesSection(posHint: "сущ. м./ж./ср. / глаг. несов./сов. / прил. / нареч. …"),
            table(
                Heading(zh: "变格 / 变位", en: "Declension / Conjugation"),
                """
                | «格|Case» | «单数|Singular» | «复数|Plural» |
                |---|---|---|
                | «主格|Nom.» | ⟨…⟩ | ⟨…⟩ |
                | «属格|Gen.» | ⟨…⟩ | ⟨…⟩ |
                | «与格|Dat.» | ⟨…⟩ | ⟨…⟩ |
                | «宾格|Acc.» | ⟨…⟩ | ⟨…⟩ |
                | «工具格|Instr.» | ⟨…⟩ | ⟨…⟩ |
                | «前置格|Prep.» | ⟨…⟩ | ⟨…⟩ |
                (For verbs replace this with a table of я / ты / он / мы / вы / они in the present (or perfective future), then the past forms m/f/n/pl and the imperative. For adjectives give the long forms m/f/n/pl, short forms and comparative. Mark stress in every form.)
                """
            ),
            Section(
                heading: Heading(zh: "支配", en: "Government"),
                body: "- ⟨case or preposition required, e.g. кого? что? + Р.п., or —⟩"
            ),
            collocationsSection("collocation or idiom with the headword"),
            synonymsSection,
            notesSection("stress shifts, aspect choice or case errors"),
        ],
        extraRules: [
            "Always mark word stress with an acute accent (´) on Russian words, including in examples.",
        ]
    )

    // MARK: Arabic — Almaany / Hans Wehr

    static let arabicTemplate = LearnerDictTemplate(
        languages: [.arabic],
        languageName: "Arabic (Modern Standard Arabic)",
        reference: "Almaany (المعاني), the Hans Wehr Dictionary of Modern Written Arabic and المعجم الوسيط",
        headerLines: [
            "**«标音写法|Vocalized»** ⟨headword with full harakat⟩ · **«转写|Transliteration»** ⟨ALA-LC or DIN transliteration⟩",
            "**«词根|Root»** ⟨root letters separated by spaces, e.g. ك ت ب⟩ · **«词型|Pattern»** ⟨morphological pattern (وزن), e.g. فِعَال⟩ · **«词性|POS»** ⟨اسم / فعل / صفة / حرف …⟩",
        ],
        sections: [
            sensesSection(posHint: "اسم / فعل / صفة / ظرف / حرف …"),
            table(
                Heading(zh: "词形", en: "Forms"),
                """
                | «项目|Item» | «形式|Form» |
                |---|---|
                | ⟨for nouns/adjectives: singular, dual, plural (mark broken plural جمع تكسير), feminine; for verbs: verb form I–X, past (الماضي), present (المضارع), imperative (الأمر), verbal noun (المصدر), active participle (اسم الفاعل), passive participle (اسم المفعول)⟩ | ⟨fully vocalized form⟩ |
                """
            ),
            Section(
                heading: Heading(zh: "同根词", en: "Same-Root Words"),
                body: """
                - **⟨vocalized word from the same root⟩** ⟨meaning⟩
                - **⟨vocalized word from the same root⟩** ⟨meaning⟩
                - **⟨vocalized word from the same root⟩** ⟨meaning⟩
                """
            ),
            collocationsSection("collocation or expression with the headword"),
            synonymsSection,
            notesSection("MSA vs. dialect usage, preposition the verb takes, or gender agreement"),
        ],
        extraRules: [
            "Write all Arabic words with full vocalization (harakat) and give transliteration in parentheses for example sentences.",
        ]
    )

    // MARK: Hindi — Shabdkosh / Oxford Hindi–English Dictionary (McGregor)

    static let hindiTemplate = LearnerDictTemplate(
        languages: [.hindi],
        languageName: "Hindi",
        reference: "Shabdkosh, the Oxford Hindi–English Dictionary (R. S. McGregor) and the Platts Dictionary",
        headerLines: [
            "**«转写|Transliteration»** ⟨IAST transliteration⟩ · /⟨IPA⟩/ · **«词性|POS»** ⟨संज्ञा / क्रिया / विशेषण / क्रिया-विशेषण …⟩",
            "**«性|Gender»** ⟨पुल्लिंग / स्त्रीलिंग, or —⟩ · **«词源|Origin»** ⟨तत्सम / तद्भव / देशज / Persian–Arabic / English⟩",
        ],
        sections: [
            sensesSection(posHint: "संज्ञा पु. / संज्ञा स्त्री. / क्रिया स. / क्रिया अ. / विशेषण …"),
            table(
                Heading(zh: "词形", en: "Forms"),
                """
                | «形式|Form» | «词形|Word» |
                |---|---|
                | ⟨for nouns: direct singular, direct plural, oblique singular, oblique plural; for verbs: stem, infinitive, habitual present, past (perfective), future, imperative with तुम and आप, and whether it takes ने; for adjectives: whether it inflects (-आ ending) and its forms⟩ | ⟨word⟩ |
                """
            ),
            collocationsSection("compound verb, postposition phrase or idiom with the headword"),
            synonymsSection,
            notesSection("gender agreement, ने construction, or Hindi vs. Urdu word choice"),
        ],
        extraRules: [
            "Write Hindi in Devanagari and give IAST transliteration in parentheses for example sentences.",
        ]
    )

    // MARK: Bengali — Samsad / Bangla Academy

    static let bengaliTemplate = LearnerDictTemplate(
        languages: [.bengali],
        languageName: "Bengali",
        reference: "the Samsad Bengali–English Dictionary and the Bangla Academy dictionaries",
        headerLines: [
            "**«转写|Transliteration»** ⟨ISO 15919 transliteration⟩ · /⟨IPA⟩/ · **«词性|POS»** ⟨বিশেষ্য / ক্রিয়া / বিশেষণ / ক্রিয়াবিশেষণ …⟩",
            "**«词源|Origin»** ⟨তৎসম / তদ্ভব / দেশি / বিদেশি (source language)⟩",
        ],
        sections: [
            sensesSection(posHint: "বিশেষ্য / ক্রিয়া / বিশেষণ / ক্রিয়াবিশেষণ / অব্যয় …"),
            table(
                Heading(zh: "词形", en: "Forms"),
                """
                | «形式|Form» | «词形|Word» |
                |---|---|
                | ⟨for verbs: root (ধাতু), verbal noun, present, past, future with the তুই / তুমি / আপনি levels; for nouns: objective (-কে), genitive (-এর/-র), locative (-এ/-তে), plural (-রা/-গুলো) and classifier (-টা/-টি)⟩ | ⟨word⟩ |
                """
            ),
            collocationsSection("compound verb or expression with the headword"),
            synonymsSection,
            notesSection("সাধু vs. চলিত forms, honorific level or spelling variants"),
        ],
        extraRules: [
            "Write Bengali in Bengali script and give transliteration in parentheses for example sentences.",
        ]
    )
}
