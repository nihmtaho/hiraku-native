import Foundation
import HirakuBridge
import HirakuModels
import SQLite3
import Testing

@Test func sqliteWALSurvivesReopen() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("hiraku-wal-test", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }
    let url = dir.appendingPathComponent("hiraku.sqlite")

    for _ in 0..<2 {
        var handle: OpaquePointer?
        #expect(sqlite3_open(url.path, &handle) == SQLITE_OK)
        guard let db = handle else {
            Issue.record("sqlite3_open returned no handle")
            return
        }
        defer { sqlite3_close(db) }
        #expect(sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil) == SQLITE_OK)
        var modeStatement: OpaquePointer?
        #expect(sqlite3_prepare_v2(db, "PRAGMA journal_mode", -1, &modeStatement, nil) == SQLITE_OK)
        defer { sqlite3_finalize(modeStatement) }
        #expect(sqlite3_step(modeStatement) == SQLITE_ROW)
        let mode = String(cString: sqlite3_column_text(modeStatement, 0))
        #expect(mode.lowercased() == "wal")
        #expect(sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS t (v INTEGER)", nil, nil, nil) == SQLITE_OK)
        #expect(sqlite3_exec(db, "INSERT INTO t VALUES (1)", nil, nil, nil) == SQLITE_OK)
        var statement: OpaquePointer?
        #expect(sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM t", -1, &statement, nil) == SQLITE_OK)
        defer { sqlite3_finalize(statement) }
        #expect(sqlite3_step(statement) == SQLITE_ROW)
        #expect(sqlite3_column_int(statement, 0) >= 1)
    }
}

@Test func bridgePingAndUnknownMethod() async throws {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("hiraku-bridge-\(UUID().uuidString).sqlite").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let bridge = HirakuBridge()
    try await bridge.open(path: path)
    #expect(try await bridge.call(.ping).isEmpty)
    do {
        _ = try await bridge.call(methodRaw(99))
        Issue.record("unknown method did not fail")
    } catch let error as HirakuContractError {
        #expect(error.code == .notFound)
    }
    await bridge.close()
}

private func methodRaw(_ raw: Int32) -> Hiraku_V1_Method { Hiraku_V1_Method(rawValue: Int(raw)) ?? .unspecified }

@Test func eventHubYieldsChanges() async {
    let hub = EventHub()
    var iterator = await hub.stream().makeAsyncIterator()
    await hub.send(Hiraku_V1_ChangeSet())
    let change = await iterator.next()
    #expect(change != nil)
}
