import Foundation

protocol AIBackendProtocol: Sendable {
    func send(_ request: OpenAIRequest) async throws -> AICoachingResponse
}
