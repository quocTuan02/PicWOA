import XCTest
@testable import Picwoa

// MARK: - Test doubles

private actor CountingBackend: AIBackendProtocol {
    private(set) var callCount = 0
    let response: AICoachingResponse

    init(response: AICoachingResponse = .placeholder) {
        self.response = response
    }

    func send(_ request: OpenAIRequest) async throws -> AICoachingResponse {
        callCount += 1
        return response
    }

    func count() -> Int { callCount }
}

private struct ThrowingBackend: AIBackendProtocol {
    let error: Error
    func send(_ request: OpenAIRequest) async throws -> AICoachingResponse {
        throw error
    }
}

final class AIOrchestratorTests: XCTestCase {

    /// Pose triggers the "chin_down" rule → has issues → eligible to call AI.
    private func chinDownPose() -> PoseObservation {
        PoseObservation(
            head: CGPoint(x: 0.5, y: 0.5),
            neck: CGPoint(x: 0.5, y: 0.62),
            leftShoulder: CGPoint(x: 0.35, y: 0.65),
            rightShoulder: CGPoint(x: 0.65, y: 0.65),
            hip: nil, leftKnee: nil, rightKnee: nil,
            leftFoot: nil, rightFoot: nil,
            confidence: 0.9, timestamp: 0
        )
    }

    private let validResponse = AICoachingResponse(
        mainCue: "Xoay người sang phải",
        secondaryCue: nil,
        cameraInstruction: nil,
        score: 4,
        feedback: "Tốt lắm!",
        editingRecipe: .neutral
    )

    @MainActor
    func testThrottleSingleCallWithinWindow() async {
        let backend = CountingBackend(response: validResponse)
        let orch = AIOrchestrator(config: .default, backend: backend, ruleEngine: RuleEngine())
        let pose = chinDownPose()

        await orch.process(pose: pose, scene: .outdoor)
        await orch.process(pose: pose, scene: .outdoor)

        let calls = await backend.count()
        XCTAssertEqual(calls, 1, "Throttle phải chặn call thứ 2 trong cùng window")
    }

    @MainActor
    func testAISuccessEmitsValidatedResponse() async {
        let backend = CountingBackend(response: validResponse)
        let orch = AIOrchestrator(config: .default, backend: backend, ruleEngine: RuleEngine())
        var iterator = orch.coachingStream.makeAsyncIterator()

        await orch.process(pose: chinDownPose(), scene: .outdoor)

        // Emission 1 = Tier-3 fallback (immediate)
        let immediate = await iterator.next()
        XCTAssertNotNil(immediate)
        // Emission 2 = AI response (override)
        let aiEmission = await iterator.next()
        XCTAssertEqual(aiEmission?.mainCue, validResponse.mainCue)
        XCTAssertEqual(orch.lastMetrics?.decisionPath, .aiSuccess)
    }

    @MainActor
    func testFallbackOnTimeout() async {
        let backend = ThrowingBackend(error: OpenAIError.timeout)
        let orch = AIOrchestrator(config: .default, backend: backend, ruleEngine: RuleEngine())
        var iterator = orch.coachingStream.makeAsyncIterator()

        await orch.process(pose: chinDownPose(), scene: .outdoor)

        let fallback = await iterator.next()
        XCTAssertNotNil(fallback)
        XCTAssertFalse(fallback?.mainCue.isEmpty ?? true)
        XCTAssertEqual(orch.lastMetrics?.decisionPath, .aiTimeout)
    }

    @MainActor
    func testReadyToCaptureSkipsAI() async {
        let backend = CountingBackend(response: validResponse)
        let orch = AIOrchestrator(config: .default, backend: backend, ruleEngine: RuleEngine())

        // Valid pose → readyToCapture → does not call AI
        let goodPose = PoseObservation(
            head: CGPoint(x: 0.5, y: 0.55),
            neck: CGPoint(x: 0.5, y: 0.60),
            leftShoulder: CGPoint(x: 0.38, y: 0.65),
            rightShoulder: CGPoint(x: 0.62, y: 0.65),
            hip: CGPoint(x: 0.5, y: 0.8),
            leftKnee: nil, rightKnee: nil,
            leftFoot: nil, rightFoot: nil,
            confidence: 0.95, timestamp: 0
        )
        await orch.process(pose: goodPose, scene: .outdoor)

        let calls = await backend.count()
        XCTAssertEqual(calls, 0, "readyToCapture không được gọi AI")
        XCTAssertEqual(orch.lastMetrics?.decisionPath, .ruleEngineClean)
    }

    @MainActor
    func testShouldInvalidateCache() {
        let orch = AIOrchestrator(config: .default, backend: CountingBackend(), ruleEngine: RuleEngine())
        let a = CoachingRule(id: "chin_down", message: "", direction: nil, priority: 1)
        let b = CoachingRule(id: "left_shoulder_low", message: "", direction: nil, priority: 2)
        let c = CoachingRule(id: "too_far", message: "", direction: nil, priority: 3)

        let r1 = RuleEngineResult(issues: [a], readyToCapture: false)
        let r1Same = RuleEngineResult(issues: [a], readyToCapture: false)
        let r2 = RuleEngineResult(issues: [b, c], readyToCapture: false)

        XCTAssertFalse(orch.shouldInvalidateCache(current: r1Same, previous: r1))
        XCTAssertTrue(orch.shouldInvalidateCache(current: r2, previous: r1))
    }

    func testConfigDefaultUsesMock() {
        // Test bundle has no Config.plist → default mock mode.
        let config = AIConfig.load(bundle: .main)
        XCTAssertTrue(config.useMockAI)
        let backend = AIConfig.makeBackend(config: config)
        XCTAssertTrue(backend is MockAIClient)
    }
}
