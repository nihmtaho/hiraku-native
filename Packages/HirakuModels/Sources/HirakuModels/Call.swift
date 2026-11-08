import Foundation

/// Anything that can call the core contract, so tests can fake the transport.
public protocol HirakuCalling: Sendable {
    func call(_ method: Hiraku_V1_Method, request: Data) async throws -> Data
}
