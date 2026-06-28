import Foundation

/// AI pipeline configuration, loaded from `Config.plist` in the app bundle.
///
/// Resilient: if `Config.plist` is not bundled (the file is in `.gitignore`
/// and not yet added to `project.yml`), the default config enables `useMockAI = true` —
/// the app still runs the demo entirely via `MockAIClient`, no API key needed.
///
/// Keys read from the plist: `OPENAI_API_KEY`, `USE_MOCK_AI`, `AI_MODEL_DEFAULT`,
/// `AI_THROTTLE_SECONDS`, `AI_TIMEOUT_SECONDS`.
struct AIConfig: Sendable {

    let apiKey: String?
    let useMockAI: Bool
    let model: String
    let throttleSeconds: TimeInterval
    let timeoutSeconds: TimeInterval

    /// Cache TTL for AICoachingResponse (seconds) — AI_ORCHESTRATION_SPEC §8.
    let cacheTTLSeconds: TimeInterval = 30

    static let `default` = AIConfig(
        apiKey: nil,
        useMockAI: true,
        model: "gpt-4o-mini",
        throttleSeconds: 4.0,
        timeoutSeconds: 8.0   // realistic for live gpt-4o-mini; 2s timed out before the reply
    )

    /// Load config from `Config.plist`. Returns `.default` if not found.
    static func load(bundle: Bundle = .main) -> AIConfig {
        guard
            let url = bundle.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(
                from: data, format: nil
            ) as? [String: Any]
        else {
            return .default
        }

        let rawKey = (dict["OPENAI_API_KEY"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRealKey = rawKey.map { !$0.isEmpty && $0 != "YOUR_API_KEY_HERE" } ?? false

        // useMockAI defaults to true; if there's no real key, always use mock.
        let useMock = (dict["USE_MOCK_AI"] as? Bool ?? true) || !hasRealKey

        return AIConfig(
            apiKey: hasRealKey ? rawKey : nil,
            useMockAI: useMock,
            model: (dict["AI_MODEL_DEFAULT"] as? String) ?? "gpt-4o-mini",
            throttleSeconds: numeric(dict["AI_THROTTLE_SECONDS"]) ?? 4.0,
            timeoutSeconds: numeric(dict["AI_TIMEOUT_SECONDS"]) ?? 8.0
        )
    }

    /// Select the appropriate backend based on config. This is the single Mock ↔ Real swap point.
    /// Use real OpenAI only when `useMockAI == false` AND a real key exists.
    static func makeBackend(config: AIConfig = .load()) -> any AIBackendProtocol {
        guard !config.useMockAI, let key = config.apiKey else {
            #if DEBUG
            print("⚠️ [AIConfig] Dùng MockAIClient — KHÔNG gọi OpenAI. " +
                  "useMockAI=\(config.useMockAI), hasRealKey=\(config.apiKey != nil). " +
                  "Điền OPENAI_API_KEY thật + USE_MOCK_AI=false trong Config.plist để bật AI thật.")
            #endif
            return MockAIClient()
        }
        #if DEBUG
        print("✅ [AIConfig] Dùng OpenAIClient (model=\(config.model)) — AI thật đã bật.")
        #endif
        return OpenAIClient(apiKey: key, model: config.model, timeout: config.timeoutSeconds)
    }

    /// Select the pose-suggestion provider. Same Mock ↔ Real swap point as `makeBackend`:
    /// AI ranking only when a real key exists, otherwise the offline `MockPoseSuggestionProvider`.
    static func makePoseSuggestionProvider(config: AIConfig = .load()) -> any PoseSuggestionProviding {
        guard !config.useMockAI, let key = config.apiKey else {
            return MockPoseSuggestionProvider()
        }
        return OpenAIPoseSuggestionProvider(apiKey: key, model: config.model, timeout: config.timeoutSeconds)
    }

    private static func numeric(_ value: Any?) -> TimeInterval? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return TimeInterval(i) }
        if let s = value as? String { return TimeInterval(s) }
        return nil
    }
}
