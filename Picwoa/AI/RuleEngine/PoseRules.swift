import Foundation

struct PoseRule: Sendable {
    let id: String
    let evaluate: @Sendable (PoseAnalysisResult?, SceneContext) -> CoachingRule?
}

enum PoseRules {
    /// Classifies the deviation level by magnitude (normalized metric).
    /// `value` < `mediumAt` → small; < `largeAt` → medium; otherwise → large.
    static func magnitude(_ value: Float, mediumAt: Float, largeAt: Float) -> Magnitude {
        if value >= largeAt { return .large }
        if value >= mediumAt { return .medium }
        return .small
    }

    static let all: [PoseRule] = [
        chinDown,
        leftShoulderLow,
        rightShoulderLow,
        torsoFacingCamera,
        bodyOffCenter,
        tooFar,
        tooClose,
        noPersonInFrame
    ]

    // Priority 1 — person not yet in frame
    static let noPersonInFrame = PoseRule(id: "no_person") { pose, _ in
        guard pose != nil else {
            return CoachingRule(id: "no_person", message: "Bước vào khung hình", direction: nil, priority: 1)
        }
        return nil
    }

    // Priority 2 — chin too low (chinAngle = head.y - neck.y, negative = chin down)
    static let chinDown = PoseRule(id: "chin_down") { pose, _ in
        guard let pose, pose.chinAngle < -0.08 else { return nil }
        let mag = magnitude(-pose.chinAngle, mediumAt: 0.12, largeAt: 0.20)
        return CoachingRule(id: "chin_down", message: "Ngẩng đầu lên", direction: .up, priority: 2, magnitude: mag)
    }

    // Priority 3 — left shoulder too low (shoulderDelta > 0 = left lower)
    static let leftShoulderLow = PoseRule(id: "left_shoulder_low") { pose, _ in
        guard let pose, pose.shoulderDelta > 0.05 else { return nil }
        let mag = magnitude(pose.shoulderDelta, mediumAt: 0.10, largeAt: 0.15)
        return CoachingRule(id: "left_shoulder_low", message: "Nhấc vai trái lên", direction: .up, priority: 3, magnitude: mag)
    }

    // Priority 3 — right shoulder too low
    static let rightShoulderLow = PoseRule(id: "right_shoulder_low") { pose, _ in
        guard let pose, pose.shoulderDelta < -0.05 else { return nil }
        let mag = magnitude(-pose.shoulderDelta, mediumAt: 0.10, largeAt: 0.15)
        return CoachingRule(id: "right_shoulder_low", message: "Nhấc vai phải lên", direction: .up, priority: 3, magnitude: mag)
    }

    // Priority 4 — torso facing straight at the camera (wide shoulder span)
    static let torsoFacingCamera = PoseRule(id: "torso_facing") { pose, _ in
        guard let pose, pose.torsoWidth > 0.25 else { return nil }
        let mag = magnitude(pose.torsoWidth, mediumAt: 0.32, largeAt: 0.40)
        return CoachingRule(id: "torso_facing", message: "Xoay người 15° sang phải", direction: .rotateRight, priority: 4, magnitude: mag)
    }

    // Priority 5 — off center
    static let bodyOffCenter = PoseRule(id: "off_center") { pose, _ in
        guard let pose else { return nil }
        // Deviation = distance to the frame center (0.5).
        let mag = magnitude(abs(pose.frameCenterX - 0.5), mediumAt: 0.22, largeAt: 0.30)
        if pose.frameCenterX < 0.35 {
            return CoachingRule(id: "off_center_right", message: "Dịch sang phải một chút", direction: .right, priority: 5, magnitude: mag)
        } else if pose.frameCenterX > 0.65 {
            return CoachingRule(id: "off_center_left", message: "Dịch sang trái một chút", direction: .left, priority: 5, magnitude: mag)
        }
        return nil
    }

    // Priority 6 — too far (narrow shoulder span)
    static let tooFar = PoseRule(id: "too_far") { pose, _ in
        guard let pose, pose.torsoWidth < 0.1 else { return nil }
        // Narrower shoulders → farther away → larger magnitude (measure below the 0.1 threshold).
        let mag = magnitude(0.1 - pose.torsoWidth, mediumAt: 0.04, largeAt: 0.07)
        return CoachingRule(id: "too_far", message: "Bước lại gần hơn", direction: .forward, priority: 6, magnitude: mag)
    }

    // Priority 6 — too close (wide shoulder span)
    static let tooClose = PoseRule(id: "too_close") { pose, _ in
        guard let pose, pose.torsoWidth > 0.5 else { return nil }
        // Wider shoulders → closer → larger magnitude (measure beyond the 0.5 threshold).
        let mag = magnitude(pose.torsoWidth - 0.5, mediumAt: 0.1, largeAt: 0.2)
        return CoachingRule(id: "too_close", message: "Lùi ra xa hơn", direction: .backward, priority: 6, magnitude: mag)
    }
}
