import Foundation
import HirakuModels
import HirakuTesting
import Testing

@testable import FeatureFolders

@MainActor
private func makeController(
    catalog: FakeCatalog = FakeCatalog(),
    events: FakeChangeEvents = FakeChangeEvents()
) -> FoldersController {
    FoldersController(folders: catalog, events: events, clock: ManualClock())
}

@MainActor
@Test func loadsExistingFoldersInOrder() async throws {
    let catalog = FakeCatalog(folders: [
        Folder(id: FolderID(rawValue: "f2"), name: "N4", position: 2, deckCount: 1, noteCount: 3),
        Folder(id: FolderID(rawValue: "f1"), name: "N5", position: 1, deckCount: 0, noteCount: 0),
    ])
    let controller = makeController(catalog: catalog)
    await controller.load()
    #expect(controller.phase == .ready)
    #expect(controller.rows.map(\.name) == ["N5", "N4"])
}

@MainActor
@Test func emptyListStaysReadySoTheViewShowsTheEmptyState() async {
    let controller = makeController()
    await controller.load()
    #expect(controller.phase == .ready)
    #expect(controller.rows.isEmpty)
}

@MainActor
@Test func createTrimsTheNameAndReloads() async {
    let controller = makeController()
    #expect(await controller.create(name: "  N5  "))
    #expect(controller.rows.map(\.name) == ["N5"])
}

@MainActor
@Test func invalidNamesNeverReachTheRepository() async {
    let controller = makeController()
    #expect(!(await controller.create(name: "   ")))
    let long = String(repeating: "a", count: 101)
    #expect(!(await controller.create(name: long)))
    #expect(controller.rows.isEmpty)
    #expect(FoldersController.validate(name: "  ") == .empty)
    #expect(FoldersController.validate(name: long) == .tooLong)
}

@MainActor
@Test func renameAndDeleteUpdateTheRows() async throws {
    let controller = makeController()
    _ = await controller.create(name: "N5")
    let folder = try #require(controller.rows.first)
    #expect(await controller.rename(folder, to: "N5 mới"))
    #expect(controller.rows.first?.name == "N5 mới")
    await controller.delete(folder)
    #expect(controller.rows.isEmpty)
}

@MainActor
@Test func moveSwapsAndPersistsTheOrder() async throws {
    let controller = makeController()
    _ = await controller.create(name: "A")
    _ = await controller.create(name: "B")
    let second = try #require(controller.rows.last)
    await controller.move(second, up: true)
    #expect(controller.rows.map(\.name) == ["B", "A"])
    await controller.move(controller.rows.first!, up: true)
    #expect(controller.rows.map(\.name) == ["B", "A"])
}

@MainActor
@Test func dragToIndexMovesTheFolderAndPersists() async throws {
    let controller = makeController()
    _ = await controller.create(name: "A")
    _ = await controller.create(name: "B")
    _ = await controller.create(name: "C")
    let last = try #require(controller.rows.last)
    await controller.move(last, toIndex: 0)
    #expect(controller.rows.map(\.name) == ["C", "A", "B"])
}

@MainActor
@Test func repositoryFailureShowsTheErrorAndKeepsThePhase() async {
    let failing = FailingFolders()
    let controller = FoldersController(folders: failing, events: FakeChangeEvents(), clock: ManualClock())
    await controller.load()
    #expect(controller.phase == .failed)
    #expect(controller.lastError == "error.generic.message")
    #expect(!(await controller.create(name: "N5")))
    #expect(controller.lastError == "error.save.failed")
}

private struct FailingFolders: FolderRepository {
    func folders() async throws -> [Folder] { throw FailingFoldersError.offline }
    func createFolder(name: String) async throws -> FolderID { throw FailingFoldersError.offline }
    func renameFolder(_ id: FolderID, name: String) async throws { throw FailingFoldersError.offline }
    func deleteFolder(_ id: FolderID) async throws { throw FailingFoldersError.offline }
    func reorderFolders(_ ids: [FolderID]) async throws { throw FailingFoldersError.offline }
}

private enum FailingFoldersError: Error {
    case offline
}
