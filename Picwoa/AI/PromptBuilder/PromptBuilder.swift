import Foundation

struct PromptBuilder {

    static func buildChatRequest(from request: OpenAIRequest) -> [String: Any] {
        [
            "model": "gpt-4o-mini",
            "temperature": 0.7,
            "max_tokens": 300,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": buildUserMessage(from: request)]
            ]
        ]
    }

    private static func buildUserMessage(from request: OpenAIRequest) -> String {
        let issuesText = request.issues.isEmpty
            ? "Không có vấn đề nào"
            : request.issues.joined(separator: ", ")

        return """
        Phân tích tư thế chụp ảnh:
        - Cảnh: \(request.scene)
        - Tư thế: \(request.pose)
        - Vấn đề phát hiện: \(issuesText)
        - Vị trí trong frame: \(request.framePosition)

        Trả về JSON với các trường: main_cue, secondary_cue, camera_instruction, score, feedback, editing_recipe.
        """
    }

    private static let systemPrompt = """
    Bạn là nhiếp ảnh gia AI chuyên nghiệp. Nhiệm vụ của bạn là hướng dẫn người dùng chụp ảnh đẹp hơn.

    LUÔN trả lời bằng tiếng Việt. Ngắn gọn, rõ ràng.
    Gợi ý tối đa 40 ký tự cho main_cue và secondary_cue.

    Trả về đúng JSON format:
    {
      "main_cue": "string",
      "secondary_cue": "string or null",
      "camera_instruction": "string or null",
      "score": 1-5,
      "feedback": "1-2 câu tiếng Việt",
      "editing_recipe": {
        "exposure": -1.0 to 1.0,
        "contrast": -100 to 100,
        "highlights": -100 to 100,
        "shadows": -100 to 100,
        "temperature": -100 to 100,
        "vibrance": -100 to 100
      }
    }
    """
}
