import Foundation
import HirakuModels

/// Deterministic clock for controller tests; nothing waits in real time.
public final class ManualClock: AppClock, @unchecked Sendable {
    private let lock = NSLock()
    private var millis: Int64

    public init(nowMs: Int64 = 1_000) {
        self.millis = nowMs
    }

    public var nowMs: Int64 {
        lock.lock()
        defer { lock.unlock() }
        return millis
    }

    public func advance(by millis: Int64) {
        lock.lock()
        defer { lock.unlock() }
        self.millis += millis
    }

    public func sleep(for duration: Duration) async {
        let millis = Int64(duration.components.seconds) * 1_000
            + Int64(duration.components.attoseconds / 1_000_000_000_000_000)
        advance(by: millis)
    }
}

/// Change stream a test drives by hand.
public final class FakeChangeEvents: ChangeEvents, @unchecked Sendable {
    private let continuation: AsyncStream<Hiraku_V1_ChangeSet>.Continuation
    private let stream: AsyncStream<Hiraku_V1_ChangeSet>

    public init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    public func changes() -> AsyncStream<Hiraku_V1_ChangeSet> {
        stream
    }

    public func send(_ changeSet: Hiraku_V1_ChangeSet) {
        continuation.yield(changeSet)
    }
}
