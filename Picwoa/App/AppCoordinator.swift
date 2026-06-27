import Foundation

@MainActor
@Observable
final class AppCoordinator {
    let cameraEngine: CameraEngine
    let visionEngine: VisionEngine
    let ruleEngine: RuleEngine
    let orchestrator: AIOrchestrator
    let overlayViewModel: OverlayViewModel
    let cameraViewModel: CameraViewModel

    private var tasks: [Task<Void, Never>] = []
    private var hasStarted = false

    init(
        cameraEngine: CameraEngine = .shared,
        visionEngine: VisionEngine = .shared,
        ruleEngine: RuleEngine = RuleEngine(),
        aiBackend: any AIBackendProtocol = MockAIClient()
    ) {
        self.cameraEngine = cameraEngine
        self.visionEngine = visionEngine
        self.ruleEngine = ruleEngine
        self.orchestrator = AIOrchestrator(backend: aiBackend, ruleEngine: ruleEngine)
        self.overlayViewModel = OverlayViewModel()
        self.cameraViewModel = CameraViewModel(
            cameraEngine: cameraEngine,
            captureService: CaptureService(cameraEngine: cameraEngine)
        )
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        tasks.append(Task { [cameraEngine, visionEngine] in
            for await buffer in cameraEngine.sampleBufferStream {
                await visionEngine.process(sampleBuffer: buffer)
            }
        })

        tasks.append(Task { [visionEngine, orchestrator] in
            for await pose in visionEngine.poseStream {
                guard let pose else { continue }
                await orchestrator.process(pose: pose, scene: .outdoor)
            }
        })

        tasks.append(Task { [orchestrator, overlayViewModel] in
            for await coaching in orchestrator.coachingStream {
                await MainActor.run {
                    overlayViewModel.update(with: coaching)
                }
            }
        })

        tasks.append(Task { [visionEngine, overlayViewModel] in
            for await detected in visionEngine.personDetectedStream {
                await MainActor.run {
                    overlayViewModel.updatePersonDetected(detected)
                }
            }
        })
    }

    func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        hasStarted = false
        cameraEngine.stopSession()
    }
}
