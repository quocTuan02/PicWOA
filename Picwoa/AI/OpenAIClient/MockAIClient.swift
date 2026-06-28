import Foundation

final class MockAIClient: AIBackendProtocol, Sendable {
    private let responses: [AICoachingResponse]

    init(responses: [AICoachingResponse] = MockAIClient.defaultResponses) {
        self.responses = responses
    }

    func send(_ request: OpenAIRequest) async throws -> AICoachingResponse {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 300_000_000)  // 0.3s
        // Select response by issue count (deterministic, Sendable-safe — no mutable state).
        // Fewer issues → higher-scoring response; no issues → "Hoàn hảo".
        let index = max(0, responses.count - 1 - request.issues.count)
        return responses[min(index, responses.count - 1)]
    }

    static let defaultResponses: [AICoachingResponse] = [
        AICoachingResponse(
            mainCue: "Ngẩng đầu lên",
            secondaryCue: "Nhấc vai trái lên",
            cameraInstruction: nil,
            score: 3,
            feedback: "Tư thế khá ổn! Cần cải thiện góc cằm.",
            editingRecipe: EditingRecipe(
                exposure: 0.1, contrast: 10,
                highlights: -15, shadows: 20,
                temperature: 4, vibrance: 15
            ),
            overlay: [
                OverlayCue(part: "chin", type: "arrow", direction: Direction.up.rawValue),
                OverlayCue(part: "left_shoulder", type: "arrow", direction: Direction.up.rawValue)
            ]
        ),
        AICoachingResponse(
            mainCue: "Xoay người 15° sang phải",
            secondaryCue: "Nhìn về phía camera",
            cameraInstruction: "Lùi camera ra một chút",
            score: 4,
            feedback: "Góc chụp đẹp! Chỉnh tư thế thêm một chút là hoàn hảo.",
            editingRecipe: EditingRecipe(
                exposure: 0.0, contrast: 5,
                highlights: -10, shadows: 15,
                temperature: 2, vibrance: 10
            ),
            overlay: [
                OverlayCue(part: "torso", type: "arrow", direction: Direction.rotateRight.rawValue)
            ]
        ),
        AICoachingResponse(
            mainCue: "Hoàn hảo! Chụp ngay",
            secondaryCue: nil,
            cameraInstruction: nil,
            score: 5,
            feedback: "Tư thế xuất sắc! Đây là khoảnh khắc hoàn hảo.",
            editingRecipe: EditingRecipe(
                exposure: 0.05, contrast: 8,
                highlights: -12, shadows: 18,
                temperature: 3, vibrance: 12
            ),
            isReadyToCapture: true
        )
    ]
}
