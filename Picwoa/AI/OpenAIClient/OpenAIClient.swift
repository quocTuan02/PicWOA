import Foundation

enum OpenAIError: Error {
    case invalidResponse
    case timeout
    case networkError(Error)
    case parseError
}

/// HTTP client that calls the OpenAI Chat Completions API.
///
/// - Model + timeout injected from `AIConfig` (not hardcoded).
/// - Retries once on timeout / transient network error (AI_ORCHESTRATION_SPEC §6).
/// - API key kept separately in the `Authorization` header, never logged.
final class OpenAIClient: AIBackendProtocol, Sendable {
    private let apiKey: String
    private let model: String
    private let timeout: TimeInterval
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(
        apiKey: String,
        model: String = "gpt-4o-mini",
        timeout: TimeInterval = 2.0,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.timeout = timeout
        self.session = session
    }

    func send(_ request: OpenAIRequest) async throws -> AICoachingResponse {
        do {
            return try await performRequest(request)
        } catch {
            // Retry once for a transient error (timeout / lost network).
            if isRetryable(error) {
                return try await performRequest(request)
            }
            throw error
        }
    }

    private func performRequest(_ request: OpenAIRequest) async throws -> AICoachingResponse {
        var urlRequest = URLRequest(url: endpoint, timeoutInterval: timeout)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PromptBuilder.buildChatRequest(from: request, model: model)
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw OpenAIError.timeout
        } catch {
            throw OpenAIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }

        return try ResponseParser.parse(data: data)
    }

    private func isRetryable(_ error: Error) -> Bool {
        switch error {
        case OpenAIError.timeout, OpenAIError.networkError:
            return true
        default:
            return false
        }
    }
}
