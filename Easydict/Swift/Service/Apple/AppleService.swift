//
//  AppleService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation
import NaturalLanguage

// MARK: - AppleService

/// On-device language detection and Vision OCR. It is not a translation service and is never
/// shown in the service list; screenshot OCR and input-language detection use it.
@objc(EZAppleService)
public class AppleService: QueryService {
    // MARK: Public

    public override func supportsOCR() -> Bool { true }

    public override func serviceType() -> ServiceType {
        .apple
    }

    public override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    @objc
    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        languageMapper.supportedLanguages.toMMOrderedDictionary()
    }

    @nonobjc
    public override func detectText(_ text: String) async throws -> Language {
        detectTextSync(text)
    }

    /// Detect language for Objective-C callers without spinning up a Task.
    @objc
    public override func detectText(
        _ text: String,
        completionHandler: @escaping (Language, Error?) -> ()
    ) {
        completionHandler(detectTextSync(text), nil)
    }

    /// Perform OCR using Apple's Vision-based engine.
    public override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        try await ocrEngine.recognizeText(image: image, language: from)
    }

    @objc
    public func detectTextSync(_ text: String) -> Language {
        languageDetector.detectLanguage(text: text)
    }

    /// Convert NLLanguage to Language enum
    @objc
    public func languageEnum(fromAppleLanguage appleLanguage: NLLanguage) -> Language {
        languageMapper.languageEnum(from: appleLanguage)
    }

    // MARK: Internal

    @objc static let shared = AppleService()

    // MARK: Private

    private let ocrEngine = AppleOCREngine()
    private let languageMapper = AppleLanguageMapper.shared
    private let languageDetector = AppleLanguageDetector()
}
