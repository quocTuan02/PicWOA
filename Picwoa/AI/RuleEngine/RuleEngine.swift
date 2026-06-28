import Foundation

struct RuleEngine: RuleEngineProtocol {

    func evaluate(pose: PoseObservation, scene: SceneContext) -> RuleEngineResult {
        evaluate(pose: PoseAnalysisService().analyze(pose), scene: scene)
    }

    /// Optional entry — nil pose (no person in frame) flows through so the no_person rule fires.
    func evaluate(pose: PoseObservation?, scene: SceneContext) -> RuleEngineResult {
        evaluate(pose: pose.flatMap { PoseAnalysisService().analyze($0) }, scene: scene)
    }

    func evaluate(pose: PoseAnalysisResult, scene: SceneContext) -> RuleEngineResult {
        evaluate(pose: Optional(pose), scene: scene)
    }

    func evaluate(pose: PoseAnalysisResult?, scene: SceneContext) -> RuleEngineResult {
        var issues: [CoachingRule] = []

        for rule in PoseRules.all {
            if let triggered = rule.evaluate(pose, scene) {
                issues.append(triggered)
            }
        }

        let sorted = issues.sorted { $0.priority < $1.priority }
        return RuleEngineResult(
            issues: sorted,
            readyToCapture: sorted.isEmpty,
            framePosition: pose?.framePosition ?? "unknown"
        )
    }
}
