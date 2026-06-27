import AVFoundation

// CMSampleBuffer is thread-safe in practice (retain/release is atomic).
// @unchecked Sendable required for Swift 6 strict concurrency.
extension CMSampleBuffer: @unchecked Sendable {}
