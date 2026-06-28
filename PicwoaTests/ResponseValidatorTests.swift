import XCTest
@testable import Picwoa

final class ResponseValidatorTests: XCTestCase {

    private func response(
        mainCue: String = "Ngẩng đầu lên",
        score: Int = 3,
        recipe: EditingRecipe = .neutral
    ) -> AICoachingResponse {
        AICoachingResponse(
            mainCue: mainCue,
            secondaryCue: nil,
            cameraInstruction: nil,
            score: score,
            feedback: "Tư thế ổn.",
            editingRecipe: recipe
        )
    }

    func testValidResponsePasses() {
        XCTAssertTrue(ResponseValidator.validate(response()))
    }

    func testEmptyMainCueFails() {
        XCTAssertFalse(ResponseValidator.validate(response(mainCue: "   ")))
    }

    func testMainCueTooLongFails() {
        let long = String(repeating: "a", count: 41)
        XCTAssertFalse(ResponseValidator.validate(response(mainCue: long)))
    }

    func testScoreOutOfRangeFails() {
        XCTAssertFalse(ResponseValidator.validate(response(score: 0)))
        XCTAssertFalse(ResponseValidator.validate(response(score: 6)))
    }

    func testExposureOutOfRangeFails() {
        let badRecipe = EditingRecipe(
            exposure: 2.0, contrast: 0, highlights: 0,
            shadows: 0, temperature: 0, vibrance: 0
        )
        XCTAssertFalse(ResponseValidator.validate(response(recipe: badRecipe)))
    }

    func testContrastOutOfRangeFails() {
        let badRecipe = EditingRecipe(
            exposure: 0, contrast: 150, highlights: 0,
            shadows: 0, temperature: 0, vibrance: 0
        )
        XCTAssertFalse(ResponseValidator.validate(response(recipe: badRecipe)))
    }
}
