import Foundation

/// Builds the Chat Completions payload that asks the model to pick the best dáng
/// for the scene from a candidate shortlist. Output is constrained to JSON `{pose_id, reason}`.
enum PoseSuggestionPromptBuilder {

    static func buildChatRequest(
        context: PoseSuggestionContext,
        candidates: [PoseSuggestion],
        model: String
    ) -> [String: Any] {
        [
            "model": model,
            "temperature": 0.4,
            "max_tokens": 120,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage(context: context, candidates: candidates)]
            ]
        ]
    }

    private static let systemPrompt = """
    Bạn là nhiếp ảnh gia AI. Nhiệm vụ: chọn ĐÚNG MỘT dáng phù hợp nhất với bối cảnh \
    (cảnh, ánh sáng, vị trí chủ thể trong khung) từ danh sách ứng viên cho sẵn.
    Chỉ được chọn pose_id có trong danh sách. LUÔN trả lời bằng tiếng Việt.
    Trả về DUY NHẤT một JSON hợp lệ (không markdown): \
    {"pose_id": "string", "reason": "string ≤ 50 ký tự, vì sao hợp cảnh"}.
    """

    private static func userMessage(
        context: PoseSuggestionContext,
        candidates: [PoseSuggestion]
    ) -> String {
        let payload: [String: Any] = [
            "scene": context.scene.rawValue,
            "framing": context.framing,
            "frame_position": context.framePosition,
            "scene_cues": context.sceneCues,
            "candidates": candidates.map { pose -> [String: Any] in
                [
                    "pose_id": pose.id,
                    "name": pose.displayName,
                    "frame_position": pose.framePosition,
                    "body_coverage": pose.bodyCoverage,
                    "tags": pose.tags,
                    "description": pose.description
                ]
            },
            "language": "vi"
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            return "Chọn dáng hợp nhất với bối cảnh sau:\n\(json)"
        }
        let ids = candidates.map(\.id).joined(separator: ", ")
        return "Cảnh: \(context.scene.rawValue). Chọn 1 trong: \(ids)."
    }
}
