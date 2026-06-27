import Foundation

/// Coordinates the entire AI pipeline — throttle, cache, fallback, validate.
/// Every `RuleEngineResult` goes through the decision engine per AI_ORCHESTRATION_SPEC §2.
///
/// UX: always emit the RuleEngine fallback IMMEDIATELY (zero latency); the AI response
/// arrives later and overrides it. The app never waits on a blank screen or crashes because of AI.
@MainActor
final class AIOrchestrator: AICoachingProvider {

    // Dependencies
    private let backend: any AIBackendProtocol
    private let ruleEngine: RuleEngine
    private let config: AIConfig

    // Throttle + cache state
    private var lastRequestTime: Date = .distantPast
    private var cachedResponse: AICoachingResponse?
    private var cachedAt: Date = .distantPast
    private var previousResult: RuleEngineResult?
    // Latest realtime RuleEngine snapshot — what `requestAICoaching()` (button) acts on.
    private var latestResult: RuleEngineResult?

    // Observability (debug)
    private(set) var lastMetrics: OrchestratorMetrics?

    // Output stream — nonisolated so non-MainActor consumers (AppCoordinator wiring) can read it.
    nonisolated let coachingStream: AsyncStream<AICoachingResponse>
    private let continuation: AsyncStream<AICoachingResponse>.Continuation

    // Stream-driven tasks (when using start(ruleStream:sceneStream:))
    private var streamTasks: [Task<Void, Never>] = []
    private var latestScene: SceneContext = .unknown
    // In-flight AI request — cancelled & replaced when the pose materially changes, so the
    // pose loop never blocks on the network (keeps coaching smooth).
    private var aiTask: Task<Void, Never>?
    private var aiInFlight = false

    init(
        config: AIConfig = .load(),
        backend: (any AIBackendProtocol)? = nil,
        ruleEngine: RuleEngine = RuleEngine()
    ) {
        self.config = config
        self.backend = backend ?? AIConfig.makeBackend(config: config)
        self.ruleEngine = ruleEngine
        // bufferingNewest(1): the overlay only needs the latest coaching; avoids a
        // backlog of stale responses if the UI consumes slower than the emit rate (real-time path).
        (coachingStream, continuation) = AsyncStream.makeStream(
            of: AICoachingResponse.self,
            bufferingPolicy: .bufferingNewest(1)
        )
    }

    // MARK: - Stream-driven entry (integration with Dev B)

    /// Subscribe to the RuleEngine + Scene streams. AppCoordinator calls this after wiring the pipeline.
    func start(
        ruleStream: AsyncStream<RuleEngineResult>,
        sceneStream: AsyncStream<SceneContext>
    ) {
        stop()
        streamTasks.append(Task { [weak self] in
            for await scene in sceneStream {
                self?.latestScene = scene
            }
        })
        streamTasks.append(Task { [weak self] in
            for await result in ruleStream {
                guard let self else { return }
                await self.ingest(result, scene: self.latestScene)
            }
        })
    }

    func stop() {
        streamTasks.forEach { $0.cancel() }
        streamTasks.removeAll()
        aiTask?.cancel()
        aiTask = nil
        aiInFlight = false
    }

    /// Reset the cache when the user captures — AI_ORCHESTRATION_SPEC §8.
    func resetSessionCache() {
        cachedResponse = nil
        cachedAt = .distantPast
        previousResult = nil
        lastRequestTime = .distantPast
    }

    // MARK: - Button-driven entry (AI only on explicit user request)

    /// Realtime, OFFLINE path — runs only the RuleEngine and emits its coaching every frame.
    /// NEVER calls the network. Remembers the latest snapshot so `requestAICoaching()` can act
    /// on the current pose when the user taps the AI button.
    func updateRuleOnly(pose: PoseObservation?, scene: SceneContext) {
        let result = ruleEngine.evaluate(pose: pose, scene: scene)
        latestResult = result
        latestScene = scene
        emit(makeFallbackResponse(from: result))
    }

    /// User-initiated AI coaching for the CURRENT pose. One call per tap — no throttle, no
    /// polling. Awaits the network round-trip so the UI can show a loading state, then emits
    /// the AI response (or best-available fallback on error). No-op if the pose is already good.
    func requestAICoaching() async {
        guard let result = latestResult else { return }
        let startedAt = Date()

        // Already good → nothing to coach, don't spend an API call.
        if result.readyToCapture {
            emit(makeFallbackResponse(from: result))
            finish(.ruleEngineClean, since: startedAt, cacheHit: false, issues: result.issues.count)
            return
        }

        // Supersede any previous in-flight request, then call once and wait.
        aiTask?.cancel()
        aiTask = nil
        aiInFlight = true
        let request = OpenAIRequest(from: result, scene: latestScene)
        await performAICall(request: request, result: result, startedAt: startedAt)
    }

    // MARK: - Direct entry (when the orchestrator runs the RuleEngine itself)

    func process(pose: PoseObservation, scene: SceneContext) async {
        await process(pose: Optional(pose), scene: scene)
    }

    func process(pose: PoseObservation?, scene: SceneContext) async {
        let result = ruleEngine.evaluate(pose: pose, scene: scene)
        await ingest(result, scene: scene)
    }

    // MARK: - Decision engine

    private func ingest(_ result: RuleEngineResult, scene: SceneContext) async {
        let startedAt = Date()

        // Tier 3 — emit the RuleEngine result IMMEDIATELY (zero latency UX).
        emit(makeFallbackResponse(from: result))

        // Path B — no more issues → STOP, don't call AI.
        if result.readyToCapture {
            finish(.ruleEngineClean, since: startedAt, cacheHit: false, issues: result.issues.count)
            return
        }

        // Throttle + cache invalidation.
        let throttleElapsed = Date().timeIntervalSince(lastRequestTime) >= config.throttleSeconds
        let invalidated = previousResult.map { shouldInvalidateCache(current: result, previous: $0) } ?? true
        previousResult = result

        // Path C — within the throttle window and issues haven't changed much → use cached.
        guard throttleElapsed || invalidated else {
            if let cached = freshCachedResponse() { emit(cached) }
            finish(.ruleEngineThrottle, since: startedAt, cacheHit: cachedResponse != nil, issues: result.issues.count)
            return
        }

        // If a call is already running and the pose hasn't materially changed, let it finish
        // instead of cancel+restart — otherwise latency > throttle would loop forever and the
        // AI response would never reach the UI.
        if aiInFlight && !invalidated {
            finish(.ruleEngineThrottle, since: startedAt, cacheHit: freshCachedResponse() != nil, issues: result.issues.count)
            return
        }

        // Path D — call AI in a DETACHED task so the pose loop keeps consuming (smooth UX).
        // The Tier-3 fallback was already emitted above; the AI response overrides it when it
        // arrives. A material pose change cancels the in-flight call so the newer pose wins.
        lastRequestTime = Date()
        let request = OpenAIRequest(from: result, scene: scene)
        aiTask?.cancel()
        aiInFlight = true
        aiTask = Task { [weak self] in
            await self?.performAICall(request: request, result: result, startedAt: startedAt)
        }
    }

    /// Network call + emit, run OFF the pose loop. @MainActor-isolated, so the cache writes
    /// after `await` stay ordered. Cancellation = superseded by a newer pose → drop silently.
    private func performAICall(
        request: OpenAIRequest,
        result: RuleEngineResult,
        startedAt: Date
    ) async {
        do {
            let response = try await backend.send(request)
            if Task.isCancelled { return }   // superseded — the replacement owns aiInFlight
            aiInFlight = false
            guard ResponseValidator.validate(response) else {
                emit(bestAvailableResponse(aiResponse: nil, ruleResult: result))
                finish(.aiError, since: startedAt, cacheHit: false, issues: result.issues.count, reason: "invalid_response")
                return
            }
            cachedResponse = response
            cachedAt = Date()
            emit(response)
            finish(.aiSuccess, since: startedAt, cacheHit: false, issues: result.issues.count)
        } catch is CancellationError {
            return   // superseded — the replacement owns aiInFlight
        } catch {
            if Task.isCancelled { return }
            aiInFlight = false
            // Path E — timeout / error → bestAvailable (cached < 30s or rule).
            emit(bestAvailableResponse(aiResponse: nil, ruleResult: result))
            let path: DecisionPath = isTimeout(error) ? .aiTimeout : .aiError
            finish(path, since: startedAt, cacheHit: freshCachedResponse() != nil, issues: result.issues.count, reason: "\(error)")
        }
    }

    // MARK: - Fallback tiers (§6)

    /// Tier 1 AI(valid) → Tier 2 cached(<30s) → Tier 3 RuleEngine.
    private func bestAvailableResponse(
        aiResponse: AICoachingResponse?,
        ruleResult: RuleEngineResult
    ) -> AICoachingResponse {
        if let ai = aiResponse, ResponseValidator.validate(ai) { return ai }
        if let cached = freshCachedResponse() { return cached }
        return makeFallbackResponse(from: ruleResult)
    }

    private func freshCachedResponse() -> AICoachingResponse? {
        guard let cached = cachedResponse,
              Date().timeIntervalSince(cachedAt) < config.cacheTTLSeconds
        else { return nil }
        return cached
    }

    private func makeFallbackResponse(from result: RuleEngineResult) -> AICoachingResponse {
        if result.readyToCapture {
            return AICoachingResponse(
                mainCue: "Hoàn hảo! Chụp ngay",
                secondaryCue: nil,
                cameraInstruction: nil,
                score: 5,
                feedback: "Tư thế hoàn hảo!",
                editingRecipe: cachedResponse?.editingRecipe ?? .neutral,
                isReadyToCapture: true
            )
        }
        let topIssue = result.issues.first
        let overlay = result.issues.compactMap { rule -> OverlayCue? in
            guard let direction = rule.direction else { return nil }
            return OverlayCue(part: rule.id, type: "arrow", direction: direction.rawValue)
        }
        return AICoachingResponse(
            mainCue: topIssue?.message ?? "Điều chỉnh tư thế",
            secondaryCue: result.issues.dropFirst().first?.message,
            cameraInstruction: nil,
            score: max(1, 5 - result.issues.count),
            feedback: "Hãy điều chỉnh theo hướng dẫn.",
            editingRecipe: cachedResponse?.editingRecipe ?? .neutral,
            overlay: overlay
        )
    }

    // MARK: - Cache invalidation (§8)

    func shouldInvalidateCache(current: RuleEngineResult, previous: RuleEngineResult) -> Bool {
        let currentIDs = Set(current.issues.map(\.id))
        let previousIDs = Set(previous.issues.map(\.id))
        return currentIDs.symmetricDifference(previousIDs).count > 1
    }

    // MARK: - Helpers

    private func emit(_ response: AICoachingResponse) {
        continuation.yield(response)
    }

    private func isTimeout(_ error: Error) -> Bool {
        if case OpenAIError.timeout = error { return true }
        if let urlError = error as? URLError, urlError.code == .timedOut { return true }
        return false
    }

    private func finish(
        _ path: DecisionPath,
        since startedAt: Date,
        cacheHit: Bool,
        issues: Int,
        reason: String? = nil
    ) {
        let metrics = OrchestratorMetrics(
            decisionPath: path,
            executionTimeMs: Date().timeIntervalSince(startedAt) * 1000,
            cacheHit: cacheHit,
            ruleEngineIssueCount: issues,
            failureReason: reason
        )
        lastMetrics = metrics
        #if DEBUG
        metrics.log()
        #endif
    }
}
