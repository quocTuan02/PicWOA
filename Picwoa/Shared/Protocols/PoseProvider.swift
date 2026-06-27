import Foundation

protocol PoseProvider: AnyObject {
    var poseStream: AsyncStream<PoseObservation?> { get }
    var personDetectedStream: AsyncStream<Bool> { get }
}
