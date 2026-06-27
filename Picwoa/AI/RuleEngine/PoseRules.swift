import Foundation

struct PoseRule {
    let id: String
    let evaluate: (PoseObservation, SceneContext) -> CoachingRule?
}

enum PoseRules {
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

    // Priority 1 — người chưa vào frame
    static let noPersonInFrame = PoseRule(id: "no_person") { pose, _ in
        guard pose.head != nil else {
            return CoachingRule(id: "no_person", message: "Bước vào khung hình", direction: nil, priority: 1)
        }
        return nil
    }

    // Priority 2 — cằm thấp
    static let chinDown = PoseRule(id: "chin_down") { pose, _ in
        guard let head = pose.head,
              let leftShoulder = pose.leftShoulder,
              let rightShoulder = pose.rightShoulder else { return nil }
        let shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2
        guard head.y < shoulderMidY - 0.08 else { return nil }
        return CoachingRule(id: "chin_down", message: "Ngẩng đầu lên", direction: .up, priority: 2)
    }

    // Priority 3 — vai trái thấp
    static let leftShoulderLow = PoseRule(id: "left_shoulder_low") { pose, _ in
        guard let left = pose.leftShoulder, let right = pose.rightShoulder else { return nil }
        guard left.y - right.y > 0.05 else { return nil }
        return CoachingRule(id: "left_shoulder_low", message: "Nhấc vai trái lên", direction: .up, priority: 3)
    }

    // Priority 3 — vai phải thấp
    static let rightShoulderLow = PoseRule(id: "right_shoulder_low") { pose, _ in
        guard let left = pose.leftShoulder, let right = pose.rightShoulder else { return nil }
        guard right.y - left.y > 0.05 else { return nil }
        return CoachingRule(id: "right_shoulder_low", message: "Nhấc vai phải lên", direction: .up, priority: 3)
    }

    // Priority 4 — người quay thẳng vào camera
    static let torsoFacingCamera = PoseRule(id: "torso_facing") { pose, _ in
        guard let left = pose.leftShoulder,
              let right = pose.rightShoulder else { return nil }
        let width = abs(left.x - right.x)
        guard width > 0.25 else { return nil }
        return CoachingRule(id: "torso_facing", message: "Xoay người 15° sang phải", direction: .rotateRight, priority: 4)
    }

    // Priority 5 — lệch khỏi trung tâm
    static let bodyOffCenter = PoseRule(id: "off_center") { pose, _ in
        guard let leftShoulder = pose.leftShoulder,
              let rightShoulder = pose.rightShoulder else { return nil }
        let centerX = (leftShoulder.x + rightShoulder.x) / 2
        if centerX < 0.35 {
            return CoachingRule(id: "off_center_right", message: "Dịch sang phải một chút", direction: .right, priority: 5)
        } else if centerX > 0.65 {
            return CoachingRule(id: "off_center_left", message: "Dịch sang trái một chút", direction: .left, priority: 5)
        }
        return nil
    }

    // Priority 6 — quá xa
    static let tooFar = PoseRule(id: "too_far") { pose, _ in
        guard let left = pose.leftShoulder, let right = pose.rightShoulder else { return nil }
        let shoulderWidth = abs(left.x - right.x)
        guard shoulderWidth < 0.1 else { return nil }
        return CoachingRule(id: "too_far", message: "Bước lại gần hơn", direction: .forward, priority: 6)
    }

    // Priority 6 — quá gần
    static let tooClose = PoseRule(id: "too_close") { pose, _ in
        guard let left = pose.leftShoulder, let right = pose.rightShoulder else { return nil }
        let shoulderWidth = abs(left.x - right.x)
        guard shoulderWidth > 0.5 else { return nil }
        return CoachingRule(id: "too_close", message: "Lùi ra xa hơn", direction: .backward, priority: 6)
    }
}
