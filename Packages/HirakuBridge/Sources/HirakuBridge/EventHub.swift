import CHirakuBridge
import Foundation

/// Receives freshly generated changes so views can refresh without polling.
public actor EventHub {
    private var continuations: [UUID: AsyncStream<Hiraku_V1_ChangeSet>.Continuation] = [:]

    public init() {}

    public func stream() -> AsyncStream<Hiraku_V1_ChangeSet> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.remove(id) }
            }
        }
    }

    public func send(_ changeSet: Hiraku_V1_ChangeSet) {
        for continuation in continuations.values {
            continuation.yield(changeSet)
        }
    }

    private func remove(_ id: UUID) {
        continuations[id] = nil
    }
}
