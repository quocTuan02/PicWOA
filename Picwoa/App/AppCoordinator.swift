import Foundation

@MainActor
@Observable
final class AppCoordinator {
    let cameraEngine: CameraEngine
    let visionEngine: VisionEngine
    let ruleEngine: RuleEngine
    let sceneClassifier: SceneClassifierService
    let orchestrator: AIOrchestrator
    let overlayViewModel: OverlayViewModel
    let cameraViewModel: CameraViewModel

    private let sceneStore = SceneContextStore()
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

        tasks.append(Task { [cameraEngine, visionEngine, sceneClassifier, sceneStore] in
            var lastSceneClassification = Date.distantPast

            for await buffer in cameraEngine.makeSampleBufferStream() {
                await visionEngine.process(sampleBuffer: buffer)

                let now = Date()
                guard now.timeIntervalSince(lastSceneClassification) >= 5 else { continue }
                lastSceneClassification = now

                let scene = await sceneClassifier.classify(buffer)
                await sceneStore.update(scene)
            }
        })

        tasks.append(Task { [visionEngine, orchestrator, sceneStore] in
            for await pose in visionEngine.poseStream {
                let scene = await sceneStore.current()
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
        cameraEngine.stopSession()
    }
}

private actor SceneContextStore {
    private var scene: SceneContext = .unknown

    func update(_ scene: SceneContext) {
        self.scene = scene
    }

    func current() -> SceneContext {
        scene
    }
}
