import Foundation

enum OpenAIError: Error {
    case invalidResponse
    case timeout
    case networkError(Error)
    case parseError
}

final class OpenAIClient: AIBackendProtocol, Sendable {
    private let apiKey: String
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func send(_ request: OpenAIRequest) async throws -> AICoachingResponse {
        var urlRequest = URLRequest(url: endpoint, timeoutInterval: 2.0)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PromptBuilder.buildChatRequest(from: request)
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }

        return try ResponseParser.parse(data: data)
    }
}
