import Foundation

struct RuleEngine: RuleEngineProtocol {

    func evaluate(pose: PoseObservation, scene: SceneContext) -> RuleEngineResult {
        var issues: [CoachingRule] = []

        for rule in PoseRules.all {
            if let triggered = rule.evaluate(pose: pose, scene: scene) {
                issues.append(triggered)
            }
        }

        let sorted = issues.sorted { $0.priority < $1.priority }
        return RuleEngineResult(issues: sorted, readyToCapture: sorted.isEmpty)
    }
}
