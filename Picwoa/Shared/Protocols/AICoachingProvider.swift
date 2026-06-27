import Foundation

protocol AICoachingProvider: AnyObject {
    var coachingStream: AsyncStream<AICoachingResponse> { get }
}
