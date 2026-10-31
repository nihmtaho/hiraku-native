#if DEBUG
import Foundation
import HirakuBridge

// Debug-only S-8 measurement harness. Runs only when the process is launched
// with the env var HK_SPIKE_RUN=1; a normal app launch stays inert.
enum Spike8 {
    struct Numbers: Encodable {
        let platform: String
        let coldMs: Double
        let startupMedianMs: Double
        let startupRuns: Int
        let pingCount: Int
        let pingMedianMs: Double
        let pingP95Ms: Double
        let rssBeforeKB: UInt64
        let rssAfterKB: UInt64
        let error: String

        var summary: String {
            func num(_ v: Double) -> String { v.isFinite ? String(format: "%.3f ms", v) : "n/a" }
            let rss = "\(rssBeforeKB)→\(rssAfterKB) KB"
            if !error.isEmpty { return "spike8 FAILED: \(error)" }
            return "cold \(num(coldMs)); startup med \(num(startupMedianMs)); "
                + "ping med \(num(pingMedianMs)) p95 \(num(pingP95Ms)); RSS \(rss)"
        }

        var jsonText: String {
            // The artifact must always be writable, so encode by hand.
            func num(_ v: Double) -> String { v.isFinite ? String(format: "%.4f", v) : "null" }
            let errorPart = error.isEmpty ? "null" : "\"\(error)\""
            return """
            {"platform":"\(platform)","cold_ms":\(num(coldMs)),"startup_median_ms":\(num(startupMedianMs)),\
            "startup_runs":\(startupRuns),"ping_count":\(pingCount),"ping_median_ms":\(num(pingMedianMs)),\
            "ping_p95_ms":\(num(pingP95Ms)),"rss_before_kb":\(rssBeforeKB),"rss_after_kb":\(rssAfterKB),\
            "error":\(errorPart)}
            """
        }
    }

    static var runRequested: Bool {
        ProcessInfo.processInfo.environment["HK_SPIKE_RUN"] == "1"
    }

    static var platformName: String {
        #if targetEnvironment(simulator)
            return "iOS simulator"
        #elseif os(macOS)
            return "macOS"
        #else
            return "unknown"
        #endif
    }

    static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return .nan }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 1 { return sorted[mid] }
        return (sorted[mid - 1] + sorted[mid]) / 2
    }

    static func percentile(_ values: [Double], _ p: Double) -> Double {
        guard !values.isEmpty else { return .nan }
        let sorted = values.sorted()
        var index = Int((p * Double(sorted.count)).rounded())
        if index <= 0 { index = 1 }
        if index > sorted.count { index = sorted.count }
        return sorted[index - 1]
    }

    static func measure(dbPath: String) -> Numbers {
        var coldMs = Double.nan
        var startups: [Double] = []
        var perCalls: [Double] = []
        var rssBefore = UInt64(0)
        var rssAfter = UInt64(0)
        var failure = ""

        do {
            let coldStart = HirakuSpikeMetrics.timeNs()
            let coldHandle = try HirakuBridge.open(path: dbPath)
            _ = try HirakuBridge.call(handle: coldHandle, method: "ping")
            coldMs = Double(HirakuSpikeMetrics.timeNs() - coldStart) / 1_000_000
            try HirakuBridge.close(coldHandle)

            for _ in 0 ..< 20 {
                let start0 = HirakuSpikeMetrics.timeNs()
                let handle = try HirakuBridge.open(path: dbPath)
                _ = try HirakuBridge.call(handle: handle, method: "ping")
                startups.append(Double(HirakuSpikeMetrics.timeNs() - start0) / 1_000_000)
                try HirakuBridge.close(handle)
            }

            let handle = try HirakuBridge.open(path: dbPath)
            rssBefore = HirakuSpikeMetrics.rssKb()
            for _ in 0 ..< 1000 {
                let call0 = HirakuSpikeMetrics.timeNs()
                _ = try HirakuBridge.call(handle: handle, method: "ping")
                perCalls.append(Double(HirakuSpikeMetrics.timeNs() - call0) / 1_000_000)
            }
            rssAfter = HirakuSpikeMetrics.rssKb()
            try HirakuBridge.close(handle)
        } catch {
            failure = "\(error)"
        }

        let numbers = Numbers(
            platform: platformName,
            coldMs: coldMs,
            startupMedianMs: median(startups),
            startupRuns: startups.count,
            pingCount: perCalls.count,
            pingMedianMs: median(perCalls),
            pingP95Ms: percentile(perCalls, 0.95),
            rssBeforeKB: rssBefore,
            rssAfterKB: rssAfter,
            error: failure
        )

        if let path = ProcessInfo.processInfo.environment["HK_SPIKE_OUT"], !path.isEmpty {
            try? numbers.jsonText.data(using: .utf8)?.write(to: URL(fileURLWithPath: path))
        }
        return numbers
    }
}
#endif
