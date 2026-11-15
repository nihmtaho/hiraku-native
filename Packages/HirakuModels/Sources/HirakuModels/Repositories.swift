import Foundation

/// What a feature needs from the core for folders; implemented by the bridge.
public protocol FolderRepository: Sendable {
    func folders() async throws -> [Folder]
    func createFolder(name: String) async throws -> FolderID
    func renameFolder(_ id: FolderID, name: String) async throws
    func deleteFolder(_ id: FolderID) async throws
    func reorderFolders(_ ids: [FolderID]) async throws
}

public protocol DeckRepository: Sendable {
    func decks(in folder: FolderID) async throws -> [Deck]
    func createDeck(in folder: FolderID, name: String, description: String, noteType: NoteTypeID?) async throws -> DeckID
    func updateDeck(_ id: DeckID, name: String, description: String) async throws
    func deleteDeck(_ id: DeckID) async throws
    func reorderDecks(in folder: FolderID, ids: [DeckID]) async throws
    func moveDeck(_ id: DeckID, to folder: FolderID) async throws
}

public protocol NoteTypeRepository: Sendable {
    func noteTypes() async throws -> [NoteType]
}

public protocol NoteRepository: Sendable {
    func notes(in deck: DeckID, query: NoteQuery) async throws -> NotePage
    func createNote(in deck: DeckID, values: [NoteFieldValue]) async throws -> NoteID
    func updateNote(_ id: NoteID, values: [NoteFieldValue]) async throws
    func deleteNote(_ id: NoteID) async throws
    func duplicate(in deck: DeckID, term: String) async throws -> DuplicateTerm
}

/// Time crosses the layer boundary as milliseconds; only `App` implements this.
public protocol AppClock: Sendable {
    var nowMs: Int64 { get }
    func sleep(for duration: Duration) async
}

/// Change notifications from the core; a feature reloads when its entities appear.
public protocol ChangeEvents: Sendable {
    func changes() -> AsyncStream<Hiraku_V1_ChangeSet>
}

/// Load state a controller exposes to its view.
public enum LoadPhase: Equatable, Sendable {
    case loading
    case ready
    case failed
}
