import Foundation

struct AICoachingResponse: Sendable {
    let mainCue: String           // tiếng Việt, ≤ 40 ký tự
    let secondaryCue: String?
    let cameraInstruction: String?
    let score: Int                // 1–5
    let feedback: String          // tiếng Việt, 1–2 câu
    let editingRecipe: EditingRecipe

    static let placeholder = AICoachingResponse(
        mainCue: "Ngẩng đầu lên",
        secondaryCue: "Nhấc vai trái lên",
        cameraInstruction: nil,
        score: 3,
        feedback: "Tư thế ổn, cần điều chỉnh thêm một chút.",
        editingRecipe: .neutral
    )
}
