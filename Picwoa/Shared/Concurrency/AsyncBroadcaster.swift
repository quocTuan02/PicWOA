import Foundation

/// Thread-safe multicast over `AsyncStream`.
///
/// A bare `AsyncStream` supports a SINGLE iteration for its whole lifetime: once consumed
/// (or its consuming task is cancelled), re-iterating the same stream yields nothing. That
/// breaks the lifecycle `stop()` → `start()` flow, where a new consumer re-subscribes after
/// the previous one was torn down.
///
/// `AsyncBroadcaster` fixes that: every `subscribe()` returns a FRESH stream, and `yield(_:)`
/// fans the element out to all live subscribers. Subscriptions auto-detach on termination
/// (consumer finishes or its task is cancelled), so re-subscribing after a stop/start works.
final class AsyncBroadcaster<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    /// A new independent stream. Safe to call repeatedly (e.g. once per `start()`).
    func subscribe(
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            lock.unlock()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.continuations[id] = nil
                self.lock.unlock()
            }
        }
    }

    /// Fan `element` out to every live subscriber.
    func yield(_ element: Element) {
        lock.lock()
        let targets = Array(continuations.values)
        lock.unlock()
        for continuation in targets {
            continuation.yield(element)
        }
    }

    /// Finish every live subscriber and drop them.
    func finishAll() {
        lock.lock()
        let targets = Array(continuations.values)
        continuations.removeAll()
        lock.unlock()
        for continuation in targets {
            continuation.finish()
        }
    }
}
