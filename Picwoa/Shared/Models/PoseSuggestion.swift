import Foundation

/// A single reference pose from the bundled library (PRD V1: "Pose templates").
///
/// `imageName` points at an asset in `Assets.xcassets` that LOOKS LIKE a human figure
/// (illustration or photo silhouette), so the user sees a concrete dáng to copy — not a
/// stick figure. `description` fully describes the pose in Vietnamese for the top-left card.
///
/// The `scenes` / `framing` / `framePosition` / `tags` fields let the matcher prefilter
/// candidates locally, and give the AI enough context to pick the dáng that fits the scenery.
struct PoseSuggestion: Identifiable, Sendable, Codable, Equatable {
    let id: String
    /// Short name shown on the card, e.g. "Dáng nghiêng vai".
    let displayName: String
    /// Asset name in `Assets.xcassets`. A placeholder symbol is shown if the asset is missing.
    let imageName: String
    /// Full Vietnamese description of the pose — what to do with head / shoulders / hands / legs.
    let description: String
    /// Scenes this pose fits: `SceneContext.rawValue` (`indoor` / `outdoor`) or `any`.
    let scenes: [String]
    /// Target framing: `vertical_9_16` / `horizontal` / `any`.
    let framing: String
    /// Where the subject sits in the frame this pose suits: `left` / `center` / `right` / `any`.
    let framePosition: String
    /// Body coverage: `portrait` / `half` / `full_body`.
    let bodyCoverage: String
    /// Free-form cues for AI ranking, e.g. `["beach", "leading_lines", "backlight"]`.
    let tags: [String]

    /// `true` if this pose is valid for `scene` (matches the tag or is scene-agnostic).
    func matches(scene: SceneContext) -> Bool {
        scenes.contains("any") || scenes.contains(scene.rawValue)
    }

    /// `true` if this pose is valid for the given framing tag.
    func matches(framing target: String) -> Bool {
        framing == "any" || framing == target
    }

    /// `true` if this pose suits the subject's position in the frame.
    func matches(framePosition target: String) -> Bool {
        framePosition == "any" || framePosition == target
    }
}
