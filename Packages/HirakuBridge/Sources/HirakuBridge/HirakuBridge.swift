import CHirakuBridge
import Foundation
import HirakuModels

public struct HKHandle: Hashable, Sendable {
    let raw: Int64
}

public struct HirakuContractError: Error, Equatable, Sendable {
    public let code: Hiraku_V1_ErrorCode
    public let subCode: Hiraku_V1_ErrorSubCode

    public init(code: Hiraku_V1_ErrorCode, subCode: Hiraku_V1_ErrorSubCode) {
        self.code = code
        self.subCode = subCode
    }
}

/// Actor that owns one hk_* handle; features never see the C ABI.
public actor HirakuBridge: HirakuCalling {
    private var handle: HKHandle?
    private let eventHub: EventHub

    public init(eventHub: EventHub = EventHub()) {
        self.eventHub = eventHub
    }

    deinit {
        if let handle {
            _ = hk_close(handle.raw)
        }
    }

    public var changes: AsyncStream<Hiraku_V1_ChangeSet> {
        get async { await eventHub.stream() }
    }

    public func open(path: String) throws {
        if handle != nil { throw HirakuContractError(code: .invalidArgument, subCode: .unspecified) }
        var raw: hk_handle = 0
        var err = HKBytes()
        let code = path.withCString { hk_open($0, &raw, &err) }
        hk_free(err)
        guard code == 0 else { throw Self.map(code: code, body: []) }
        handle = HKHandle(raw: raw)
    }

    public func call(_ method: Hiraku_V1_Method, request: Data = Data()) async throws -> Data {
        guard let handle else { throw HirakuContractError(code: .invalidArgument, subCode: .unspecified) }
        var response = HKBytes()
        let code = request.withUnsafeBytes { buffer in
            let bytes = HKBytes(
                data: UnsafeMutablePointer<UInt8>(mutating: buffer.bindMemory(to: UInt8.self).baseAddress),
                len: UInt64(buffer.count)
            )
            return hk_call(handle.raw, UInt32(method.rawValue), bytes, &response)
        }
        let body = Self.take(response)
        guard code == 0 else { throw Self.map(code: code, body: body) }
        return Data(body)
    }

    public func close() {
        guard let handle else { return }
        self.handle = nil
        _ = hk_close(handle.raw)
    }

    private static func take(_ bytes: HKBytes) -> [UInt8] {
        defer { hk_free(bytes) }
        guard bytes.len > 0, let data = bytes.data else { return [] }
        return Array(UnsafeBufferPointer(start: data, count: Int(bytes.len)))
    }

    private static func map(code: Int32, body: [UInt8]) -> HirakuContractError {
        let decoded = (try? Hiraku_V1_Error(serializedBytes: body)) ?? Hiraku_V1_Error()
        let fallback: Hiraku_V1_ErrorCode = switch code {
        case 1: .invalidArgument
        case 2: .notFound
        case 3: .businessRule
        case 4: .storage
        case 5: .panic
        default: .unspecified
        }
        return HirakuContractError(code: decoded.code == .unspecified ? fallback : decoded.code, subCode: decoded.subCode)
    }
}
