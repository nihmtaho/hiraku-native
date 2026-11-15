import Foundation
import HirakuBridge
import HirakuModels

/// Composition root: opens the core once and hands features their protocols.
@MainActor
final class AppContainer {
    let clock = SystemClock()
    private(set) var bridge: HirakuBridge?
    private(set) var catalog: CatalogClient?

    var events: any ChangeEvents {
        BridgeChangeEvents(bridge: bridge ?? HirakuBridge())
    }

    func start() async throws {
        guard bridge == nil else { return }
        let handle = HirakuBridge()
        try await handle.open(path: try Self.databasePath())
        bridge = handle
        catalog = CatalogClient(call: handle, clock: clock)
    }

    private static func databasePath() throws -> String {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent("hiraku", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("hiraku.sqlite").path
    }
}

struct SystemClock: AppClock {
    var nowMs: Int64 { Int64((Date().timeIntervalSince1970 * 1_000).rounded()) }

    func sleep(for duration: Duration) async {
        try? await Task.sleep(for: duration)
    }
}

struct BridgeChangeEvents: ChangeEvents {
    let bridge: HirakuBridge

    func changes() -> AsyncStream<Hiraku_V1_ChangeSet> {
        AsyncStream { continuation in
            let task = Task {
                for await changeSet in await bridge.changes {
                    continuation.yield(changeSet)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
