import CHirakuBridge

// Spike-only measurement helpers exposed for the debug app harness (S-8).
public enum HirakuSpikeMetrics {
    public static func timeNs() -> UInt64 { hksample_time_ns() }
    public static func rssKb() -> UInt64 { hksample_rss_kb() }
}
