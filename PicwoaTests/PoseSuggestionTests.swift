import XCTest
@testable import Picwoa

final class PoseSuggestionTests: XCTestCase {

    // MARK: - Library

    func testBundledCatalogDecodes() {
        let library = PoseSuggestionLibrary()
        XCTAssertFalse(library.all.isEmpty, "PoseSuggestions.json should decode (or fall back to builtIn)")
    }

    func testCandidatesNeverEmptyForKnownScene() {
        let library = PoseSuggestionLibrary(all: Self.sample)
        let outdoor = library.candidates(scene: .outdoor, framing: "vertical_9_16", framePosition: "left")
        XCTAssertFalse(outdoor.isEmpty)
        // Scene-agnostic pose backstops indoor too.
        let indoor = library.candidates(scene: .indoor, framing: "vertical_9_16", framePosition: "center")
        XCTAssertFalse(indoor.isEmpty)
    }

    func testPrefilterRanksSpecificSceneAndPositionFirst() {
        let library = PoseSuggestionLibrary(all: Self.sample)
        let ranked = library.candidates(scene: .outdoor, framing: "vertical_9_16", framePosition: "left")
        // The outdoor + left pose must rank above the scene-agnostic classic.
        XCTAssertEqual(ranked.first?.id, "outdoor_left")
        XCTAssertTrue(ranked.contains { $0.id == "any_classic" })
    }

    // MARK: - Mock provider

    func testMockProviderPicksMatchingFramePosition() async throws {
        let provider = MockPoseSuggestionProvider(simulatedLatencyNanos: 0)
        let context = PoseSuggestionContext(scene: .outdoor, framing: "vertical_9_16", framePosition: "left", sceneCues: [])
        let selection = try await provider.selectSuggestion(context: context, candidates: Self.sample)
        XCTAssertEqual(selection.id, "outdoor_left")
    }

    func testMockProviderThrowsWithoutCandidates() async {
        let provider = MockPoseSuggestionProvider(simulatedLatencyNanos: 0)
        let context = PoseSuggestionContext(scene: .outdoor, framing: "vertical_9_16", framePosition: "left", sceneCues: [])
        do {
            _ = try await provider.selectSuggestion(context: context, candidates: [])
            XCTFail("Expected noCandidates error")
        } catch {
            XCTAssertTrue(error is PoseSuggestionError)
        }
    }

    // MARK: - OpenAI response parsing

    func testOpenAIParserRejectsUnknownID() {
        let json = envelope(content: #"{"pose_id":"hallucinated","reason":"x"}"#)
        XCTAssertThrowsError(try OpenAIPoseSuggestionProvider.parse(data: json, validIDs: ["outdoor_left"]))
    }

    func testOpenAIParserAcceptsValidID() throws {
        let json = envelope(content: #"{"pose_id":"outdoor_left","reason":"Hợp đường dẫn"}"#)
        let selection = try OpenAIPoseSuggestionProvider.parse(data: json, validIDs: ["outdoor_left"])
        XCTAssertEqual(selection.id, "outdoor_left")
        XCTAssertEqual(selection.reason, "Hợp đường dẫn")
    }

    // MARK: - ViewModel

    @MainActor
    func testViewModelShowsLocalThenAIOverride() async {
        let library = PoseSuggestionLibrary(all: Self.sample)
        // Provider that always picks the scene-agnostic classic, overriding the local "outdoor_left".
        let provider = FixedProvider(id: "any_classic")
        let vm = PoseSuggestionViewModel(library: library, provider: provider, throttleSeconds: 0)

        vm.update(scene: .outdoor, framePosition: "left")
        // Tier 1: local best is shown immediately.
        XCTAssertEqual(vm.currentSuggestion?.id, "outdoor_left")

        // Tier 2: AI override arrives.
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(vm.currentSuggestion?.id, "any_classic")
    }

    @MainActor
    func testViewModelIgnoresUnchangedContext() async {
        let library = PoseSuggestionLibrary(all: Self.sample)
        let provider = CountingProvider()
        let vm = PoseSuggestionViewModel(library: library, provider: provider, throttleSeconds: 0)

        vm.update(scene: .outdoor, framePosition: "left")
        vm.update(scene: .outdoor, framePosition: "left")
        try? await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertEqual(provider.callCount, 1, "Same context key should not re-trigger the AI call")
    }

    // MARK: - Fixtures

    private func envelope(content: String) -> Data {
        let escaped = content.replacingOccurrences(of: "\"", with: "\\\"")
        return Data(#"{"choices":[{"message":{"content":"\#(escaped)"}}]}"#.utf8)
    }

    static let sample: [PoseSuggestion] = [
        PoseSuggestion(id: "outdoor_left", displayName: "Outdoor Left", imageName: "x",
                       description: "d", scenes: ["outdoor"], framing: "vertical_9_16",
                       framePosition: "left", bodyCoverage: "full_body", tags: ["leading_lines"]),
        PoseSuggestion(id: "outdoor_center", displayName: "Outdoor Center", imageName: "x",
                       description: "d", scenes: ["outdoor"], framing: "vertical_9_16",
                       framePosition: "center", bodyCoverage: "half", tags: []),
        PoseSuggestion(id: "any_classic", displayName: "Classic", imageName: "x",
                       description: "d", scenes: ["any"], framing: "any",
                       framePosition: "center", bodyCoverage: "portrait", tags: ["safe"])
    ]
}

private final class FixedProvider: PoseSuggestionProviding, @unchecked Sendable {
    let id: String
    init(id: String) { self.id = id }
    func selectSuggestion(context: PoseSuggestionContext, candidates: [PoseSuggestion]) async throws -> PoseSelection {
        PoseSelection(id: id, reason: "fixed")
    }
}

private final class CountingProvider: PoseSuggestionProviding, @unchecked Sendable {
    private(set) var callCount = 0
    func selectSuggestion(context: PoseSuggestionContext, candidates: [PoseSuggestion]) async throws -> PoseSelection {
        callCount += 1
        return PoseSelection(id: candidates.first?.id ?? "", reason: nil)
    }
}
