import Foundation

/// An enriched pose issue — sends `part / direction / magnitude` as-is
/// to the model so the AI knows the direction and intensity to adjust (prompt_example/promt.md §2).
struct PoseIssue: Sendable {
    let part: String          // = CoachingRule.id
    let direction: String?    // Direction.rawValue
    let magnitude: String     // Magnitude.rawValue
}

/// Input payload for the AI — scene-aware, carries enough context for the model to suggest
/// quality output instead of just a list of IDs. Still minimal (< 300 input tokens).
struct OpenAIRequest: Sendable {
    let scene: String
    // framePosition is wired from Dev B's RuleEngineResult.framePosition (left/center/right).
    // TODO(V1): poseGoal/framing/personCount are still PLACEHOLDERS — always default, NOT yet
    // wired from app state (orientation, capture mode, multi-person). When wiring real state,
    // AppCoordinator passes them into this init. Kept in the payload so the prompt template is
    // already ready to receive them, avoiding a contract change later.
    let poseGoal: String
    let framing: String
    let framePosition: String
    let personCount: Int
    let issues: [PoseIssue]
    let sceneCues: [String]

    init(
        from result: RuleEngineResult,
        scene: SceneContext,
        poseGoal: String = "portrait",      // placeholder — see TODO(V1) above
        framing: String = "vertical_9_16",  // placeholder
        framePosition: String? = nil,        // nil → use Dev B's RuleEngineResult.framePosition
        personCount: Int = 1                 // placeholder (multi-person in V2)
    ) {
        self.scene = scene.rawValue
        self.poseGoal = poseGoal
        self.framing = framing
        self.framePosition = framePosition ?? result.framePosition
        self.personCount = personCount
        self.issues = result.issues.map {
            PoseIssue(
                part: $0.id,
                direction: $0.direction?.rawValue,
                magnitude: $0.magnitude.rawValue
            )
        }
        self.sceneCues = SceneCues.cues(for: scene)
    }

    /// JSON payload in the exact shape the prompt describes — the model receives structured input.
    var jsonPayload: [String: Any] {
        [
            "scene": scene,
            "pose_goal": poseGoal,
            "framing": framing,
            "frame_position": framePosition,
            "person_count": personCount,
            "top_issues": issues.map { issue -> [String: Any] in
                var dict: [String: Any] = ["part": issue.part, "magnitude": issue.magnitude]
                if let direction = issue.direction { dict["direction"] = direction }
                return dict
            },
            "scene_cues": sceneCues,
            "language": "vi"
        ]
    }
}

/// Heuristic mapping `SceneContext` → composition cues for the scene.
/// MVP: static map per scene. In the future, SceneAnalysis will provide real cues
/// (leading lines, depth, negative space) — just replace this function.
///
/// Safe to extend: the switch below has NO `default`, so adding a new
/// `SceneContext` case will cause a compile error here AND in `PromptTemplates.system`
/// — you can't "forget" to map a new scene (same mechanism in both places).
enum SceneCues {
    static func cues(for scene: SceneContext) -> [String] {
        switch scene {
        case .outdoor:
            return ["chiều sâu nền", "ánh sáng tự nhiên", "khoảng trống hai bên"]
        case .indoor:
            return ["không gian hẹp", "ánh sáng nhân tạo", "nền gần"]
        case .unknown:
            return []
        }
    }
}
