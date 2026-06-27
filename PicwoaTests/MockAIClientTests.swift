import XCTest
@testable import Picwoa

final class MockAIClientTests: XCTestCase {

    let client = MockAIClient()

    func testMockReturnsValidResponse() async throws {
        let request = OpenAIRequest(from: .empty, scene: .outdoor)
        let response = try await client.send(request)

        XCTAssertFalse(response.mainCue.isEmpty)
        XCTAssertGreaterThanOrEqual(response.score, 1)
        XCTAssertLessThanOrEqual(response.score, 5)
        XCTAssertFalse(response.feedback.isEmpty)
    }

    func testMockResponseInVietnamese() async throws {
        let request = OpenAIRequest(from: .empty, scene: .outdoor)
        let response = try await client.send(request)
        // Vietnamese text should not be pure ASCII
        let hasNonASCII = response.mainCue.unicodeScalars.contains { $0.value > 127 }
        XCTAssertTrue(hasNonASCII, "main_cue should be in Vietnamese: \(response.mainCue)")
    }

    func testEditingRecipeHasValues() async throws {
        let request = OpenAIRequest(from: .empty, scene: .outdoor)
        let response = try await client.send(request)
        let recipe = response.editingRecipe

        XCTAssertTrue((-1.0...1.0).contains(recipe.exposure), "exposure out of range")
        XCTAssertTrue((-100...100).contains(recipe.contrast), "contrast out of range")
    }
}
