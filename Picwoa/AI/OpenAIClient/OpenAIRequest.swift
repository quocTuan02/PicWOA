import Foundation

struct OpenAIRequest: Sendable {
    let scene: String
    let pose: String
    let issues: [String]
    let framePosition: String
    let personCount: Int

    init(from result: RuleEngineResult, scene: SceneContext, framePosition: String? = nil) {
        self.scene = scene.rawValue
        self.pose = "standing"
        self.issues = result.issues.map { $0.id }
        self.framePosition = framePosition ?? result.framePosition
        self.personCount = 1
    }

    var jsonPayload: [String: Any] {
        [
            "scene": scene,
            "pose": pose,
            "issues": issues,
            "frame_position": framePosition,
            "person_count": personCount
        ]
    }
}
