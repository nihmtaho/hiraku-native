import CHirakuBridge

// Thin, type-safe wrapper over the four ADR-21 hk_* functions.
// Spike transport only: "ping" in, empty bytes out; real contract in WP-01.

public struct HKHandle: Hashable, Sendable {
    public let raw: Int64

    init(raw: Int64) { self.raw = raw }
}

public enum HirakuBridgeError: Error {
    case badParam
    case notFound
    case businessRule
    case storage
    case internalFailure
    case unknown(code: Int32)
}

public enum HirakuBridge {
    public static func open(path: String) throws -> HKHandle {
        var handle: hk_handle = 0
        var err = HKBytes()
        let code = path.withCString { hk_open($0, &handle, &err) }
        hk_free(err)
        if code == 0 { return HKHandle(raw: handle) }
        throw mapCode(code)
    }

    // Spike payload is empty; the reply is read fully and freed immediately.
    public static func call(handle: HKHandle, method: String) throws -> [UInt8] {
        var resp = HKBytes()
        let code = method.withCString { hk_call(handle.raw, $0, HKBytes(), &resp) }
        guard code == 0 else { throw mapCode(code) }
        let reply: [UInt8]
        if resp.len > 0, resp.data != nil {
            reply = Array(UnsafeBufferPointer(start: resp.data, count: Int(resp.len)))
        } else {
            reply = []
        }
        hk_free(resp)
        return reply
    }

    public static func close(_ handle: HKHandle) throws {
        let code = hk_close(handle.raw)
        if code != 0 { throw mapCode(code) }
    }

    private static func mapCode(_ code: Int32) -> HirakuBridgeError {
        switch code {
        case 0: return .unknown(code: code)
        case 1: return .badParam
        case 2: return .notFound
        case 3: return .businessRule
        case 4: return .storage
        case 5: return .internalFailure
        default: return .unknown(code: code)
        }
    }
}
