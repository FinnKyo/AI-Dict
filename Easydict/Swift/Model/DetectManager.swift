//
//  DetectManager.swift
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SystemConfiguration

// MARK: - DetectManager

/// Manager for text detection and OCR functionality.
/// Uses Apple's on-device language detection and Vision OCR.
@objc(EZDetectManager)
@objcMembers
public final class DetectManager: NSObject {
    // MARK: Lifecycle

    /// Initializes a new detect manager with the specified query model.
    /// - Parameter model: The query model containing text and image data.
    public init(model: QueryModel) {
        self.queryModel = model

        super.init()
    }

    /// Initializes a new detect manager with an empty query model.
    public override convenience init() {
        self.init(model: QueryModel())
        self.allowsDetachedDetection = true
    }

    deinit { ocrTask?.cancel() }

    // MARK: Public

    /// The query model containing text and image data to be processed.
    public var queryModel: QueryModel

    /// The OCR service used for text recognition.
    public var ocrService: QueryService {
        AppleService.shared
    }

    // MARK: - Static Factory

    /// Creates a new detect manager with the specified query model.
    /// - Parameter model: The query model containing text and image data.
    /// - Returns: A new detect manager instance.
    @objc(managerWithModel:)
    public static func manager(with model: QueryModel) -> DetectManager {
        DetectManager(model: model)
    }

    public func cancelOCR() {
        latestOCRRequestID = nil
        ocrTask?.cancel()
        ocrTask = nil
    }

    // MARK: - Public Methods

    /// Performs OCR on the query model's image and then detects the language of the OCR result.
    /// - Parameter completion: Callback with the updated query model and optional error.
    public func ocrAndDetectText(completion: @escaping (QueryModel, Error?) -> ()) {
        ocrAndDetectText(progress: { _ in }, completion: completion)
    }

    public func ocrAndDetectText(
        progress: @escaping (String) -> (), completion: @escaping (QueryModel, Error?) -> ()
    ) {
        ocrAndDetectText(using: ocrService, progress: progress, completion: completion)
    }

    /// Detects the language of the given text with Apple's on-device detector.
    /// - Parameters:
    ///   - queryText: The text to detect the language of.
    ///   - completion: Callback with the updated query model and optional error.
    public func detectText(_ queryText: String, completion: @escaping (QueryModel, Error?) -> ()) {
        guard !queryText.isEmpty else {
            let errorMessage = "detectText cannot be nil"
            logError(errorMessage)
            completion(queryModel, QueryError.error(type: .parameter, message: errorMessage))
            return
        }

        appleService.detectText(queryText) { [weak self] appleDetectedLanguage, error in
            guard let self else {
                completion(QueryModel(), error)
                return
            }
            guard canApplyDetectedLanguage(for: queryText) else {
                completion(queryModel, staleDetectionError())
                return
            }

            handleDetectedLanguage(
                appleDetectedLanguage,
                queryText: queryText,
                error: error,
                completion: completion
            )
        }
    }

    /// Performs OCR on the query model's image.
    /// - Parameter completion: Callback with the OCR result and optional error.
    public func ocr(completion: @escaping (EZOCRResult?, Error?) -> ()) {
        performOCR(using: ocrService, completion: completion)
    }

    /// Checks if a system proxy is configured.
    /// - Returns: `true` if an HTTP proxy is enabled, `false` otherwise.
    @objc(checkIfHasProxy)
    public func checkIfHasProxy() -> Bool {
        guard let proxies = SCDynamicStoreCopyProxies(nil) as? [String: Any] else {
            return false
        }

        let httpProxy = proxies[kSCPropNetProxiesHTTPEnable as String] as? Bool
        let httpEnable = proxies[kSCPropNetProxiesHTTPEnable as String] as? Int

        return (httpProxy == true) || (httpEnable == 1)
    }

    // MARK: Internal

    @nonobjc
    func ocrAndDetectText(
        using service: QueryService, progress: @escaping (String) -> (),
        completion: @escaping (QueryModel, Error?) -> ()
    ) {
        cancelOCR()
        let requestModel = queryModel
        let requestImage = requestModel.ocrImage
        let requestAction = requestModel.actionType
        var requestInput = requestModel.inputText
        var streamedText = ""
        var lastProgressTime = Date.distantPast
        let requestLanguage = requestModel.queryFromLanguage
        let requestID = UUID()
        latestOCRRequestID = requestID
        ocrTask = performOCR(using: service, onDelta: { [weak self] delta in
            guard let self, latestOCRRequestID == requestID,
                  queryModel === requestModel, requestModel.ocrImage === requestImage,
                  requestModel.actionType == requestAction,
                  requestModel.inputText == requestInput,
                  requestModel.queryFromLanguage == requestLanguage else { return }
            streamedText += delta
            guard !streamedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  Date().timeIntervalSince(lastProgressTime) >= 0.08 else { return }
            lastProgressTime = Date()
            requestInput = streamedText
            requestModel.inputText = streamedText
            progress(streamedText)
        }) { [weak self] ocrResult, error in
            guard let self else {
                return
            }

            guard latestOCRRequestID == requestID else { return }
            ocrTask = nil
            latestOCRRequestID = nil

            // A superseded OCR request must not replace a newer screenshot preview.
            guard queryModel === requestModel,
                  requestModel.ocrImage === requestImage, requestModel.actionType == requestAction,
                  requestModel.inputText == requestInput else { return }

            // Another window can change the shared language without starting a new request here.
            guard requestModel.queryFromLanguage == requestLanguage else {
                completion(requestModel, CocoaError(.userCancelled))
                return
            }

            if error is CancellationError {
                completion(requestModel, CocoaError(.userCancelled))
                return
            }

            guard let ocrResult else {
                completion(queryModel, error)
                return
            }

            queryModel.inputText = ocrResult.mergedText
            let ocrLanguage = ocrResult.from
            if ocrLanguage != .auto {
                queryModel.detectedLanguage = ocrLanguage
                if service is StreamService {
                    queryModel.needDetectLanguage = false
                }
            }

            completion(queryModel, error)
        }
    }

    // MARK: Private

    // MARK: - Private Properties

    private var latestOCRRequestID: UUID?
    private var ocrTask: Task<(), Never>?

    private var allowsDetachedDetection = false

    private lazy var appleService: AppleService = .shared

    @discardableResult
    private func performOCR(
        using service: QueryService, onDelta: @escaping (String) -> () = { _ in },
        completion: @escaping (EZOCRResult?, Error?) -> ()
    )
        -> Task<(), Never>? {
        guard let image = queryModel.ocrImage else {
            let error = QueryError.error(type: .parameter, message: "ocr image cannot be nil")
            completion(nil, error)
            return nil
        }

        let sourceLanguage = queryModel.queryFromLanguage
        let targetLanguage = queryModel.queryTargetLanguage
        return Task {
            let (deltas, continuation) = AsyncStream<String>.makeStream()
            // Consume on the main actor and drain before completion, preserving provider order.
            let progressTask = Task { @MainActor in
                for await delta in deltas { onDelta(delta) }
            }
            do {
                let result = try await service.ocr(image, from: sourceLanguage, to: targetLanguage, onDelta: {
                    continuation.yield($0)
                })
                continuation.finish()
                await progressTask.value
                try Task.checkCancellation()
                await MainActor.run {
                    completion(result, nil)
                }
            } catch {
                continuation.finish()
                await progressTask.value
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func canApplyDetectedLanguage(for queryText: String) -> Bool {
        allowsDetachedDetection || queryModel.queryText == queryText
    }

    private func staleDetectionError() -> QueryError {
        QueryError.error(type: .parameter, message: "Stale language detection result")
    }

    /// Performs deep OCR: first OCRs with auto-detect, then re-OCRs with the detected language
    /// if a specific language wasn't already set. This improves accuracy for languages
    /// where auto-detection may be suboptimal.
    /// - Parameter completion: Callback with the OCR result and optional error.
    private func deepOCR(completion: @escaping (EZOCRResult?, Error?) -> ()) {
        /**
         System OCR result may be inaccurate when using auto-detect language, such as:

         今日は国際ホッキョクグマの日

         But if we use Japanese to OCR again, the result will be more accurate.

         TODO: If OCR text is too long, maybe we could OCR only part of the image.
         TODO: If OCR large PDF file, we should alert user to select detected language.
         */
        ocr { [weak self] ocrResult, ocrError in
            guard let self else {
                completion(nil, ocrError)
                return
            }

            guard ocrError == nil else {
                handleOCRResult(ocrResult, error: ocrError, completion: completion)
                return
            }

            // If user has specified OCR language, we don't need to detect and OCR again.
            guard !queryModel.hasQueryFromLanguage else {
                handleOCRResult(ocrResult, error: ocrError, completion: completion)
                return
            }

            /**
             Even when confidence is high (e.g., 1.0), that just means the OCR result
             text is accurate. However, the detected language from OCR may not be accurate,
             such as 'heel' which may be detected as 'Dutch'. So we need to detect
             the text language again.
             */
            let ocrText = ocrResult?.mergedText ?? ""
            detectText(ocrText) { [weak self] queryModel, detectError in
                guard let self else {
                    completion(ocrResult, detectError)
                    return
                }

                guard let ocrResult = ocrResult, detectError == nil else {
                    completion(ocrResult, detectError)
                    return
                }

                let isConfidentLanguage = ocrResult.confidence == 1.0
                    && ocrResult.from == queryModel.detectedLanguage

                if isConfidentLanguage {
                    completion(ocrResult, nil)
                    return
                }

                Task {
                    do {
                        let result = try await self.ocrService.ocr(self.queryModel)
                        await MainActor.run {
                            self.handleOCRResult(result, error: nil, completion: completion)
                        }
                    } catch {
                        await MainActor.run {
                            self.handleOCRResult(ocrResult, error: error, completion: completion)
                        }
                    }
                }
            }
        }
    }

    /// Handles the detected language by updating the query model and calling the completion handler.
    /// - Parameters:
    ///   - language: The detected language.
    ///   - error: Optional error from detection.
    ///   - completion: Callback to invoke with the updated query model and error.
    private func handleDetectedLanguage(
        _ language: Language,
        queryText: String,
        error: Error?,
        completion: @escaping (QueryModel, Error?) -> ()
    ) {
        guard canApplyDetectedLanguage(for: queryText) else {
            completion(queryModel, staleDetectionError())
            return
        }
        queryModel.detectedLanguage = language

        // If detection succeeded, we don't need to detect again temporarily.
        queryModel.needDetectLanguage = (error != nil)

        completion(queryModel, error)
    }

    /// Handles the OCR result.
    /// - Parameters:
    ///   - ocrResult: The OCR result from the primary service.
    ///   - error: Optional error from the primary OCR service.
    ///   - completion: Callback to invoke with the final OCR result and error.
    private func handleOCRResult(
        _ ocrResult: EZOCRResult?,
        error: Error?,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        guard let error = error else {
            completion(ocrResult, nil)
            return
        }

        completion(ocrResult, error)
    }
}

// MARK: - DetectManager + Async

extension DetectManager {
    /// Asynchronously detects the language of the given text.
    /// - Parameter text: The text to detect language of.
    /// - Returns: The query model with detected language set.
    @nonobjc
    public func detectText(_ text: String) async throws -> QueryModel {
        try await withCheckedThrowingContinuation { continuation in
            detectText(text) { queryModel, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: queryModel)
                }
            }
        }
    }

    /// Asynchronously performs OCR on the query model's image.
    /// - Returns: The OCR result with recognized text.
    @nonobjc
    public func ocr() async throws -> EZOCRResult {
        try await withCheckedThrowingContinuation { continuation in
            ocr { ocrResult, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let ocrResult {
                    continuation.resume(returning: ocrResult)
                } else {
                    continuation.resume(throwing: QueryError.error(type: .api, message: "OCR failed"))
                }
            }
        }
    }
}
