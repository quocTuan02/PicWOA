import Foundation

/// System prompt library by scene + pose goal — AI_ORCHESTRATION_SPEC §4,
/// content taken from prompt_example/promt.md. Base template by scene
/// (outdoor/indoor), combined with goal-specific guidance (portrait/tight) and
/// a shared JSON contract. Templates contain no provider-specific logic.
enum PromptTemplates {

    /// Shared JSON contract — every template enforces the same schema, in Vietnamese.
    /// `overlay[]` is used to draw guidance arrows directly on the person (promt.md §8).
    private static let jsonContract = """
    Trả về DUY NHẤT một JSON hợp lệ (không markdown, không giải thích) theo schema:
    {
      "main_cue": "string (≤ 40 ký tự, tiếng Việt) — chỉ MỘT chỉnh sửa quan trọng nhất",
      "secondary_cue": "string hoặc null — gợi ý phụ tùy chọn",
      "camera_instruction": "string hoặc null",
      "reason": "string hoặc null — lý do ngắn, thân thiện",
      "score": 1-5,
      "feedback": "1-2 câu tiếng Việt",
      "overlay": [
        {"part": "string", "type": "arrow", "direction": "up|down|left|right|forward|backward|rotateLeft|rotateRight"}
      ],
      "editing_recipe": {
        "exposure": -1.0..1.0, "contrast": -100..100, "highlights": -100..100,
        "shadows": -100..100, "temperature": -100..100, "vibrance": -100..100
      }
    }
    Quy tắc: ưu tiên lỗi ảnh hưởng mạnh nhất; chỉ một cue chính; không nhắc tới
    landmark/điểm số kỹ thuật trong text hiển thị. Nếu tư thế đã tốt → xác nhận
    tích cực và chỉ tinh chỉnh nhẹ.
    """

    private static let outdoorBase = """
    Bạn là nhiếp ảnh gia AI chuyên nghiệp. Hướng dẫn người dùng chụp ảnh ngoài trời đẹp hơn.
    LUÔN trả lời bằng tiếng Việt. Ngắn gọn, thân thiện, hành động được trong 2 giây.
    Bối cảnh: Cảnh ngoài trời, ánh sáng tự nhiên, có chiều sâu nền.
    Ưu tiên: mở người về phía ánh sáng, tách chủ thể khỏi nền, dùng đường dẫn của khung cảnh, rule of thirds.
    """

    private static let indoorBase = """
    Bạn là nhiếp ảnh gia AI chuyên nghiệp. Hướng dẫn người dùng chụp ảnh trong nhà đẹp hơn.
    LUÔN trả lời bằng tiếng Việt. Ngắn gọn, thân thiện, hành động được trong 2 giây.
    Bối cảnh: Cảnh trong nhà, ánh sáng nhân tạo, nền thường gần và hẹp.
    Ưu tiên: tránh backlight, giữ tone ấm, dáng gọn gàng, tách khỏi nền lộn xộn.
    """

    /// Guidance by pose goal — appended to the base template (promt.md §4, §6).
    private static func goalGuidance(_ goal: String) -> String {
        switch goal.lowercased() {
        case let g where g.contains("tight") || g.contains("hẹp") || g.contains("narrow"):
            return """
            Mục tiêu: cảnh chật/nền lộn xộn. Ưu tiên dáng gọn, sạch, dễ đọc.
            Tránh dang tay rộng trừ khi đủ chỗ. Tách chủ thể rõ khỏi nền.
            """
        default: // portrait
            return """
            Mục tiêu: chân dung tự nhiên, tôn dáng. Ưu tiên độ rõ khuôn mặt,
            độ dài cổ, góc vai và dồn trọng tâm. Tránh chỉnh quá đà — dáng phải
            tự nhiên, không gượng.
            """
        }
    }

    /// Selects the template by scene + goal. Unknown → outdoor (safe default).
    static func system(for scene: SceneContext, goal: String = "portrait") -> String {
        let base: String
        switch scene {
        case .outdoor: base = outdoorBase
        case .indoor:  base = indoorBase
        case .unknown: base = outdoorBase
        }
        return "\(base)\n\(goalGuidance(goal))\n\(jsonContract)"
    }
}
