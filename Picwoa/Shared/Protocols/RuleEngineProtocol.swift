import Foundation

protocol RuleEngineProtocol: Sendable {
    func evaluate(pose: PoseObservation, scene: SceneContext) -> RuleEngineResult
}
