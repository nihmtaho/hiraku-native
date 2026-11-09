import Foundation
@testable import HirakuBridge
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

@Test func gradeResponsePublishesChangeSet() throws {
    let change = Hiraku_V1_Change.with {
        $0.entityID = "card-1"
        $0.kind = .upsert
        $0.entity = .card
    }
    let response = Hiraku_V1_GradeResponse.with {
        $0.nextDueMs = 1
        $0.changes = Hiraku_V1_ChangeSet.with { $0.changes = [change] }
    }
    let decoded = HirakuBridge.changeSet(method: .grade, response: Array(try response.serializedData()))
    #expect(decoded?.changes.count == 1)
    #expect(HirakuBridge.changeSet(method: .ping, response: Array(try response.serializedData())) == nil)
}

@Test func bridgePublishesGradeChangeSet() async throws {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("hiraku-publish-\(UUID().uuidString).sqlite").path
    defer { try? FileManager.default.removeItem(atPath: path) }

    let bridge = HirakuBridge()
    try await bridge.open(path: path)
    try seedCard(path: path, cardID: "card-publish")

    let queue = try await bridge.call(.buildQueue, request: try Hiraku_V1_BuildQueueRequest.with {
        $0.nowMs = 1_000_000
        $0.limit = 10
    }.serializedData())
    let decodedQueue = try Hiraku_V1_BuildQueueResponse(serializedBytes: queue)
    #expect(decodedQueue.items.count == 1, "queue = \(decodedQueue.items.count)")

    let cardID = decodedQueue.items.first?.cardID ?? "missing"
    var iterator = await bridge.changes.makeAsyncIterator()
    let request = Hiraku_V1_GradeRequest.with {
        $0.cardID = cardID
        $0.rating = .good
        $0.nowMs = 1_000_000
    }
    let payload = try request.serializedData()
    _ = try await bridge.call(.grade, request: payload)
    let event = await iterator.next()
    #expect(event?.changes.count == 1)
    #expect(event?.changes.first?.entityID == cardID)
    await bridge.close()
}

private func seedCard(path: String, cardID: String) throws {
    var handle: OpaquePointer?
    #expect(sqlite3_open(path, &handle) == SQLITE_OK)
    guard let db = handle else { throw CocoaError(.fileReadUnknown) }
    defer { sqlite3_close(db) }
    let sql = """
    INSERT INTO folders (id, name, position, created_at, updated_at) VALUES ('f1','F',1,0,0);
    INSERT INTO decks (id, folder_id, note_type_id, name, position, created_at, updated_at)
      VALUES ('d1','f1','nt-system-ja','D',1,0,0);
    INSERT INTO notes (id, deck_id, note_type_id, fields, sort_field, search_text, created_at, updated_at)
      VALUES ('card-publish','d1','nt-system-ja','{}','x','x',0,0);
    INSERT INTO cards (id, note_id, template_id, created_at, updated_at)
      VALUES ('card-publish','card-publish','ct-system-ja',0,0);
    """
    let exec = sqlite3_exec(db, sql, nil, nil, nil)
    #expect(exec == SQLITE_OK, "seed exec = \(exec)")
    var statement: OpaquePointer?
    #expect(sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM cards", -1, &statement, nil) == SQLITE_OK)
    defer { sqlite3_finalize(statement) }
    #expect(sqlite3_step(statement) == SQLITE_ROW)
    #expect(sqlite3_column_int(statement, 0) == 1, "seed count = \(sqlite3_column_int(statement, 0))")
}
