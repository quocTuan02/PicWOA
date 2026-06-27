import SwiftUI

struct SkeletonOverlay: View {
    let pose: PoseObservation?

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                guard let pose else { return }
                draw(pose: pose, in: context, size: size)
            }
            .opacity(pose != nil ? 1 : 0)
            .animation(Anim.normal, value: pose != nil)
        }
        .allowsHitTesting(false)
    }

    private func draw(pose: PoseObservation, in context: GraphicsContext, size: CGSize) {
        let lines: [(CGPoint?, CGPoint?)] = [
            (pose.head, pose.neck),
            (pose.neck, pose.leftShoulder),
            (pose.neck, pose.rightShoulder),
            (pose.leftShoulder, pose.hip),
            (pose.rightShoulder, pose.hip),
            (pose.leftShoulder, pose.leftKnee),
            (pose.rightShoulder, pose.rightKnee),
            (pose.hip, pose.leftKnee),
            (pose.hip, pose.rightKnee),
            (pose.leftKnee, pose.leftFoot),
            (pose.rightKnee, pose.rightFoot),
        ]

        var path = Path()
        for (start, end) in lines {
            guard let s = start, let e = end else { continue }
            path.move(to: convert(s, size: size))
            path.addLine(to: convert(e, size: size))
        }
        context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 2)

        // Joints
        let joints: [CGPoint?] = [
            pose.head, pose.neck,
            pose.leftShoulder, pose.rightShoulder,
            pose.hip, pose.leftKnee, pose.rightKnee,
            pose.leftFoot, pose.rightFoot,
        ]
        for joint in joints.compactMap({ $0 }) {
            let pt = convert(joint, size: size)
            let rect = CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.6)))
        }
    }

    private func convert(_ point: CGPoint, size: CGSize) -> CGPoint {
        // PoseObservation uses normalized coords: x=0..1 left→right, y=0..1 top→bottom
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SkeletonOverlay(pose: PoseObservation(
            head: CGPoint(x: 0.5, y: 0.1),
            neck: CGPoint(x: 0.5, y: 0.2),
            leftShoulder: CGPoint(x: 0.38, y: 0.3),
            rightShoulder: CGPoint(x: 0.62, y: 0.3),
            hip: CGPoint(x: 0.5, y: 0.55),
            leftKnee: CGPoint(x: 0.4, y: 0.72),
            rightKnee: CGPoint(x: 0.6, y: 0.72),
            leftFoot: CGPoint(x: 0.38, y: 0.9),
            rightFoot: CGPoint(x: 0.62, y: 0.9),
            confidence: 0.9,
            timestamp: 0
        ))
    }
}
