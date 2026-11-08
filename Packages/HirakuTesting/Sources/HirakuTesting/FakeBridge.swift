import Foundation
import HirakuModels

/// Test double for the core transport: answers from a handler instead of C.
public actor FakeBridge: HirakuCalling {
    public typealias Handler = @Sendable (Hiraku_V1_Method, Data) throws -> Data

    private var handler: Handler

    public init(handler: @escaping Handler = { _, _ in Data() }) {
        self.handler = handler
    }

    public func setHandler(_ handler: @escaping Handler) {
        self.handler = handler
    }

    public func call(_ method: Hiraku_V1_Method, request: Data) async throws -> Data {
        try handler(method, request)
    }
}
