import Foundation

struct RuleEngine: RuleEngineProtocol {

    func evaluate(pose: PoseObservation, scene: SceneContext) -> RuleEngineResult {
        evaluate(pose: PoseAnalysisService().analyze(pose), scene: scene)
    }

    func evaluate(pose: PoseObservation?, scene: SceneContext) -> RuleEngineResult {
        guard let pose else {
            return evaluate(pose: Optional<PoseAnalysisResult>.none, scene: scene)
        }
        return evaluate(pose: pose, scene: scene)
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
