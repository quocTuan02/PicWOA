import Foundation

/// AI-backed pose picker — calls OpenAI Chat Completions to rank the candidate shortlist
/// by how well each dáng fits the scenery. Mirrors `OpenAIClient`: injected key/model/timeout,
/// retry once on transient errors, key kept only in the Authorization header (never logged).
///
/// On any failure the caller keeps the local prefilter's top candidate, so the card never breaks.
final class OpenAIPoseSuggestionProvider: PoseSuggestionProviding, Sendable {
    private let apiKey: String
    private let model: String
    private let timeout: TimeInterval
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(
        apiKey: String,
        model: String = "gpt-4o-mini",
        timeout: TimeInterval = 4.0,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.timeout = timeout
        self.session = session
    }

    func selectSuggestion(
        context: PoseSuggestionContext,
        candidates: [PoseSuggestion]
    ) async throws -> PoseSelection {
        guard !candidates.isEmpty else { throw PoseSuggestionError.noCandidates }
        let validIDs = Set(candidates.map(\.id))
        do {
            return try await performRequest(context: context, candidates: candidates, validIDs: validIDs)
        } catch let error as URLError where error.code == .timedOut {
            return try await performRequest(context: context, candidates: candidates, validIDs: validIDs)
        }
    }

    private func performRequest(
        context: PoseSuggestionContext,
        candidates: [PoseSuggestion],
        validIDs: Set<String>
    ) async throws -> PoseSelection {
        var urlRequest = URLRequest(url: endpoint, timeoutInterval: timeout)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PoseSuggestionPromptBuilder.buildChatRequest(
            context: context, candidates: candidates, model: model
        )
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PoseSuggestionError.invalidResponse
        }
        return try Self.parse(data: data, validIDs: validIDs)
    }

    /// Parse the Chat Completions envelope → the `{pose_id, reason}` JSON in `choices[0].message.content`.
    /// Rejects any id not in the candidate set, so the AI can never invent a pose.
    static func parse(data: Data, validIDs: Set<String>) throws -> PoseSelection {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String,
            let contentData = content.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
            let poseID = parsed["pose_id"] as? String,
            validIDs.contains(poseID)
        else {
            throw PoseSuggestionError.invalidResponse
        }
        let reason = (parsed["reason"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return PoseSelection(id: poseID, reason: reason)
    }
}
