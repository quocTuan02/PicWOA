import Foundation

protocol AICoachingProvider: AnyObject {
    nonisolated var coachingStream: AsyncStream<AICoachingResponse> { get }
}
