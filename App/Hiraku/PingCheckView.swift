#if DEBUG
import HirakuBridge
import SwiftUI

// Debug-only S-8 check: open a scratch DB, ping through the bridge, close.
// Spike shell keeps plain strings; String Catalog and COPY come with product UI.
struct PingCheckView: View {
    @Binding var result: String

    var body: some View {
        VStack(spacing: 8) {
            Button("S-8 ping check") { run() }
            Text(verbatim: result)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .onAppear(perform: measureIfRequested)
    }

    private func run() {
        Task {
            let bridge = HirakuBridge()
            do {
                try await bridge.open(path: Spike8DB.scratchPath())
                let reply = try await bridge.call(.ping)
                await bridge.close()
                result = "ping OK, reply bytes: \(reply.count)"
            } catch {
                result = "ping FAILED: \(error)"
            }
        }
    }

    // Measurement run only when launched with HK_SPIKE_RUN=1 (env, debug only).
    private func measureIfRequested() {
        guard Spike8.runRequested else { return }
        result = "measuring…"
        Task.detached {
            let numbers = await Spike8.measure(dbPath: Spike8DB.scratchPath())
            await MainActor.run {
                self.result = numbers.summary
            }
        }
    }
}

enum Spike8DB {
    static func scratchPath() -> String {
        // :memory: is not addressable through path-based hk_open; use a scratch file.
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("../../.agents/tmp/m0-06")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("hiraku-s8.sqlite").path
    }
}
#endif
