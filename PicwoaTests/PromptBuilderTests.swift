import XCTest
@testable import Picwoa

final class PromptBuilderTests: XCTestCase {

    private func sampleRequest(scene: SceneContext) -> OpenAIRequest {
        let issues = [
            CoachingRule(id: "chin_down", message: "Ngẩng đầu lên", direction: .up, priority: 1),
            CoachingRule(id: "left_shoulder_low", message: "Nhấc vai trái", direction: .up, priority: 2)
        ]
        let result = RuleEngineResult(issues: issues, readyToCapture: false)
        return OpenAIRequest(from: result, scene: scene)
    }

    func testPayloadContainsRequiredFields() {
        let body = PromptBuilder.buildChatRequest(from: sampleRequest(scene: .outdoor), model: "gpt-4o-mini")

        XCTAssertEqual(body["model"] as? String, "gpt-4o-mini")
        XCTAssertNotNil(body["messages"])
        let messages = body["messages"] as? [[String: Any]]
        XCTAssertEqual(messages?.count, 2)
        XCTAssertEqual(messages?.first?["role"] as? String, "system")
        XCTAssertEqual(messages?.last?["role"] as? String, "user")
    }

    func testModelNotHardcoded() {
        let body = PromptBuilder.buildChatRequest(from: sampleRequest(scene: .outdoor), model: "gpt-4o")
        XCTAssertEqual(body["model"] as? String, "gpt-4o")
    }

    func testSceneSelectsTemplate() {
        let outdoor = PromptTemplates.system(for: .outdoor)
        let indoor = PromptTemplates.system(for: .indoor)
        XCTAssertNotEqual(outdoor, indoor)
        // unknown → outdoor (safe default)
        XCTAssertEqual(PromptTemplates.system(for: .unknown), outdoor)
    }

    func testSystemPromptIsVietnamese() {
        let prompt = PromptTemplates.system(for: .outdoor)
        let hasNonASCII = prompt.unicodeScalars.contains { $0.value > 127 }
        XCTAssertTrue(hasNonASCII, "System prompt phải bằng tiếng Việt")
    }

    func testUserMessageIncludesIssueIDs() {
        let body = PromptBuilder.buildChatRequest(from: sampleRequest(scene: .indoor))
        let messages = body["messages"] as? [[String: Any]]
        let userContent = messages?.last?["content"] as? String ?? ""
        XCTAssertTrue(userContent.contains("chin_down"))
        XCTAssertTrue(userContent.contains("left_shoulder_low"))
    }
}
