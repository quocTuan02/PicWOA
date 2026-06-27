import Foundation

@MainActor
final class AIOrchestrator: AICoachingProvider {

    private let backend: any AIBackendProtocol
    private let ruleEngine: RuleEngine
    private let throttleInterval: TimeInterval = 3.0

    private var lastRequestTime: Date = .distantPast
    private var cachedResponse: AICoachingResponse?

    private let coachingContinuation: AsyncStream<AICoachingResponse>.Continuation
    nonisolated let coachingStream: AsyncStream<AICoachingResponse>

    init(backend: any AIBackendProtocol = MockAIClient(), ruleEngine: RuleEngine = RuleEngine()) {
        self.backend = backend
        self.ruleEngine = ruleEngine
        let (stream, continuation) = AsyncStream<AICoachingResponse>.makeStream()
        coachingStream = stream
        coachingContinuation = continuation
    }

    func process(pose: PoseObservation, scene: SceneContext) async {
        await process(pose: Optional(pose), scene: scene)
    }

    func process(pose: PoseObservation?, scene: SceneContext) async {
        let result = ruleEngine.evaluate(pose: pose, scene: scene)

        let fallbackResponse = makeFallbackResponse(from: result)
        emit(fallbackResponse)

        guard Date().timeIntervalSince(lastRequestTime) >= throttleInterval else { return }
        guard !result.issues.isEmpty else { return }

        lastRequestTime = Date()
        let request = OpenAIRequest(from: result, scene: scene)

        do {
            let response = try await backend.send(request)
            cachedResponse = response
            emit(response)
        } catch {
            // Fallback: already emitted above
        }
    }

    private func emit(_ response: AICoachingResponse) {
        coachingContinuation.yield(response)
    }

    private func makeFallbackResponse(from result: RuleEngineResult) -> AICoachingResponse {
        if result.readyToCapture {
            return AICoachingResponse(
                mainCue: "Hoàn hảo! Chụp ngay",
                secondaryCue: nil,
                cameraInstruction: nil,
                score: 5,
                feedback: "Tư thế hoàn hảo!",
                editingRecipe: cachedResponse?.editingRecipe ?? .neutral
            )
        }
        let topIssue = result.issues.first
        return AICoachingResponse(
            mainCue: topIssue?.message ?? "Điều chỉnh tư thế",
            secondaryCue: result.issues.dropFirst().first?.message,
            cameraInstruction: nil,
            score: max(1, 5 - result.issues.count),
            feedback: "Hãy điều chỉnh theo hướng dẫn.",
            editingRecipe: cachedResponse?.editingRecipe ?? .neutral
        )
    }
}
