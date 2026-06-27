import Foundation

protocol PoseProvider: AnyObject {
    nonisolated var poseStream: AsyncStream<PoseObservation?> { get }
    nonisolated var personDetectedStream: AsyncStream<Bool> { get }
}
