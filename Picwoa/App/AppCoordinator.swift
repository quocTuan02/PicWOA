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

    private let sceneClassifier: SceneClassifierService
    private var latestSceneContext: SceneContext = .outdoor
    private var tasks: [Task<Void, Never>] = []
    private var hasStarted = false

    init(
        cameraEngine: CameraEngine = .shared,
        visionEngine: VisionEngine = .shared,
        ruleEngine: RuleEngine = RuleEngine(),
        sceneClassifier: SceneClassifierService = SceneClassifierService(),
        aiBackend: any AIBackendProtocol = MockAIClient()
    ) {
        self.cameraEngine = cameraEngine
        self.visionEngine = visionEngine
        self.ruleEngine = ruleEngine
        self.sceneClassifier = sceneClassifier
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
            for await buffer in cameraEngine.makeSampleBufferStream() {
                await visionEngine.process(sampleBuffer: buffer)
            }
        })

        tasks.append(Task { [weak self, cameraEngine, sceneClassifier] in
            var lastClassificationTime = Date.distantPast
            for await buffer in cameraEngine.makeSampleBufferStream() {
                guard Date().timeIntervalSince(lastClassificationTime) >= 5 else { continue }
                lastClassificationTime = Date()
                let scene = await sceneClassifier.classify(buffer)
                await MainActor.run {
                    self?.latestSceneContext = scene
                }
            }
        })

        tasks.append(Task { [weak self, visionEngine, orchestrator, overlayViewModel] in
            for await pose in visionEngine.poseStream {
                await MainActor.run { overlayViewModel.updatePose(pose) }
                guard let pose else { continue }
                let scene = await MainActor.run { self?.latestSceneContext ?? .outdoor }
                await orchestrator.process(pose: pose, scene: scene)
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
        latestSceneContext = .outdoor
        cameraEngine.stopSession()
    }
}
