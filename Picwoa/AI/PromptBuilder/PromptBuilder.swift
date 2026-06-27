import Foundation

/// Compiler that turns structured app data into an OpenAI Chat Completions payload.
/// Scene-aware + goal-aware: selects the system prompt by `SceneContext` and pose goal.
/// Model is injected from config, not hardcoded. Payload optimized to < 300 input tokens
/// (sends only structured issues + scene cues, not raw landmarks).
struct PromptBuilder {

    static func buildChatRequest(from request: OpenAIRequest, model: String = "gpt-4o-mini") -> [String: Any] {
        let scene = SceneContext(rawValue: request.scene) ?? .unknown
        return [
            "model": model,
            "temperature": 0.7,
            "max_tokens": 300,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": PromptTemplates.system(for: scene, goal: request.poseGoal)],
                ["role": "user", "content": buildUserMessage(from: request)]
            ]
        ]
    }

    /// User message = structured JSON payload (shape per promt.md §2).
    /// Sends part + direction + magnitude + scene_cues so the AI can suggest accurately.
    private static func buildUserMessage(from request: OpenAIRequest) -> String {
        let payload = request.jsonPayload
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            return "Phân tích tư thế và bối cảnh sau, đưa ra gợi ý:\n\(json)"
        }
        // Safe fallback if serialization fails — still keeps the issue IDs.
        let issuesText = request.issues.isEmpty ? "không có" : request.issues.map(\.part).joined(separator: ", ")
        return "Cảnh: \(request.scene). Vấn đề: \(issuesText)."
    }
}
