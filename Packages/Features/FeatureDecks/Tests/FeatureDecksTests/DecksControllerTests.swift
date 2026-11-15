import Foundation
import HirakuModels
import HirakuTesting
import Testing

@testable import FeatureDecks

private let folder = Folder(id: FolderID(rawValue: "f1"), name: "N5", position: 1, deckCount: 0, noteCount: 0)
private let other = Folder(id: FolderID(rawValue: "f2"), name: "N4", position: 2, deckCount: 0, noteCount: 0)
private let systemType = NoteType(
    id: NoteTypeID(rawValue: "nt-system-ja"),
    name: "Từ vựng Nhật",
    isSystem: true,
    fields: [
        NoteTypeField(id: "nf-term", role: .term, name: "Từ", ord: 1, inputKind: .text, required: true, searchable: true),
        NoteTypeField(id: "nf-meaning", role: .meaning, name: "Nghĩa", ord: 2, inputKind: .text, required: true, searchable: true),
    ],
    frontFieldIDs: ["nf-term"],
    backFieldIDs: ["nf-meaning"],
    typingAnswerFieldID: "nf-term"
)

@MainActor
private func makeController(catalog: FakeCatalog, folder: Folder = folder) async -> DecksController {
    await catalog.setNoteTypes([systemType])
    return DecksController(
        folder: folder,
        decks: catalog,
        folders: catalog,
        noteTypes: catalog,
        events: FakeChangeEvents(),
        clock: ManualClock()
    )
}

@MainActor
@Test func loadKeepsOnlyThisFoldersDecksInOrder() async throws {
    let catalog = FakeCatalog(folders: [folder, other], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    await controller.load()
    #expect(controller.phase == .ready)
    #expect(controller.rows.isEmpty)
    #expect(controller.canMove)
    #expect(controller.otherFolders.map(\.name) == ["N4"])
    #expect(controller.defaultNoteType?.isSystem == true)
}

@MainActor
@Test func createUsesTheSystemNoteTypeAndShowsTheDeck() async {
    let catalog = FakeCatalog(folders: [folder], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    #expect(await controller.create(name: "  Động từ  ", description: " nhóm 1 "))
    #expect(controller.rows.map(\.name) == ["Động từ"])
    #expect(controller.rows.first?.noteTypeID.rawValue == "nt-system-ja")
}

@MainActor
@Test func editUpdatesNameAndDescription() async throws {
    let catalog = FakeCatalog(folders: [folder], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    _ = await controller.create(name: "Cũ", description: "")
    let deck = try #require(controller.rows.first)
    #expect(await controller.update(deck, name: "Mới", description: "mô tả"))
    #expect(controller.rows.first?.name == "Mới")
    #expect(controller.rows.first?.description == "mô tả")
}

@MainActor
@Test func invalidNamesAreRejectedBeforeTheRepository() async {
    let catalog = FakeCatalog(folders: [folder], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    #expect(!(await controller.create(name: "", description: "")))
    #expect(controller.rows.isEmpty)
}

@MainActor
@Test func moveSendsTheDeckToAnotherFolder() async throws {
    let catalog = FakeCatalog(folders: [folder, other], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    _ = await controller.create(name: "Động từ", description: "")
    let deck = try #require(controller.rows.first)
    await controller.move(deck, to: other)
    #expect(controller.rows.isEmpty)
    #expect(try await catalog.decks(in: other.id).count == 1)
}

@MainActor
@Test func reorderSwapsNeighboursAndIgnoresTheEnds() async throws {
    let catalog = FakeCatalog(folders: [folder], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    _ = await controller.create(name: "A", description: "")
    _ = await controller.create(name: "B", description: "")
    let second = try #require(controller.rows.last)
    await controller.reorder(second, up: true)
    #expect(controller.rows.map(\.name) == ["B", "A"])
    await controller.reorder(controller.rows.first!, up: true)
    #expect(controller.rows.map(\.name) == ["B", "A"])
}

@MainActor
@Test func listOnMovePersistsTheNewOrder() async throws {
    let catalog = FakeCatalog(folders: [folder], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    _ = await controller.create(name: "A", description: "")
    _ = await controller.create(name: "B", description: "")
    await controller.moveRows(from: IndexSet(integer: 1), to: 0)
    #expect(controller.rows.map(\.name) == ["B", "A"])
}

@MainActor
@Test func deleteRemovesTheDeckAndItsNotes() async throws {
    let catalog = FakeCatalog(folders: [folder], noteTypes: [systemType])
    let controller = await makeController(catalog: catalog)
    _ = await controller.create(name: "A", description: "")
    let deck = try #require(controller.rows.first)
    _ = try await catalog.createNote(in: deck.id, values: [
        NoteFieldValue(fieldID: "nf-term", value: "水"),
        NoteFieldValue(fieldID: "nf-meaning", value: "nước"),
    ])
    await controller.delete(deck)
    #expect(controller.rows.isEmpty)
    #expect(try await catalog.notes(in: deck.id, query: NoteQuery()).total == 0)
}

@MainActor
@Test func loadFailureShowsTheError() async {
    let controller = DecksController(
        folder: folder,
        decks: FailingDecks(),
        folders: FailingDecks(),
        noteTypes: FailingDecks(),
        events: FakeChangeEvents(),
        clock: ManualClock()
    )
    await controller.load()
    #expect(controller.phase == .failed)
    #expect(controller.lastError == "error.generic.message")
}

private struct FailingDecks: DeckRepository, FolderRepository, NoteTypeRepository {
    func decks(in folder: FolderID) async throws -> [Deck] { throw Failure.offline }
    func createDeck(in folder: FolderID, name: String, description: String, noteType: NoteTypeID?) async throws -> DeckID { throw Failure.offline }
    func updateDeck(_ id: DeckID, name: String, description: String) async throws { throw Failure.offline }
    func deleteDeck(_ id: DeckID) async throws { throw Failure.offline }
    func reorderDecks(in folder: FolderID, ids: [DeckID]) async throws { throw Failure.offline }
    func moveDeck(_ id: DeckID, to folder: FolderID) async throws { throw Failure.offline }
    func folders() async throws -> [Folder] { throw Failure.offline }
    func createFolder(name: String) async throws -> FolderID { throw Failure.offline }
    func renameFolder(_ id: FolderID, name: String) async throws { throw Failure.offline }
    func deleteFolder(_ id: FolderID) async throws { throw Failure.offline }
    func reorderFolders(_ ids: [FolderID]) async throws { throw Failure.offline }
    func noteTypes() async throws -> [NoteType] { throw Failure.offline }

    private enum Failure: Error { case offline }
}
