import Foundation
import HirakuModels

/// In-memory catalog for controller tests; it keeps the ordering and the duplicate rule.
public actor FakeCatalog: FolderRepository, DeckRepository, NoteTypeRepository, NoteRepository {
    private var folderRows: [Folder]
    private var deckRows: [Deck]
    private var noteRows: [Note]
    private var typeRows: [NoteType]
    private var nextID = 1

    public init(
        folders: [Folder] = [],
        decks: [Deck] = [],
        notes: [Note] = [],
        noteTypes: [NoteType] = []
    ) {
        self.folderRows = folders
        self.deckRows = decks
        self.noteRows = notes
        self.typeRows = noteTypes
    }

    public func setNoteTypes(_ types: [NoteType]) {
        typeRows = types
    }

    public func folders() async throws -> [Folder] {
        folderRows.sorted { $0.position < $1.position }
    }

    public func createFolder(name: String) async throws -> FolderID {
        let id = FolderID(rawValue: "f\(takeID())")
        folderRows.append(Folder(id: id, name: name, position: folderRows.count + 1, deckCount: 0, noteCount: 0))
        return id
    }

    public func renameFolder(_ id: FolderID, name: String) async throws {
        guard let index = folderRows.firstIndex(where: { $0.id == id }) else { throw FakeCatalogError.notFound }
        folderRows[index].name = name
    }

    public func deleteFolder(_ id: FolderID) async throws {
        folderRows.removeAll { $0.id == id }
        deckRows.removeAll { $0.folderID == id }
    }

    public func reorderFolders(_ ids: [FolderID]) async throws {
        for (offset, id) in ids.enumerated() {
            guard let index = folderRows.firstIndex(where: { $0.id == id }) else { throw FakeCatalogError.notFound }
            folderRows[index].position = offset + 1
        }
    }

    public func decks(in folder: FolderID) async throws -> [Deck] {
        deckRows.filter { $0.folderID == folder }.sorted { $0.position < $1.position }
    }

    public func createDeck(
        in folder: FolderID,
        name: String,
        description: String,
        noteType: NoteTypeID?
    ) async throws -> DeckID {
        let id = DeckID(rawValue: "d\(takeID())")
        deckRows.append(Deck(
            id: id,
            folderID: folder,
            name: name,
            description: description,
            position: deckRows.count + 1,
            noteTypeID: noteType ?? typeRows.first.map(\.id) ?? NoteTypeID(rawValue: "nt"),
            noteCount: 0,
            stateCounts: StateCounts(new: 0, learning: 0, known: 0)
        ))
        return id
    }

    public func updateDeck(_ id: DeckID, name: String, description: String) async throws {
        guard let index = deckRows.firstIndex(where: { $0.id == id }) else { throw FakeCatalogError.notFound }
        deckRows[index].name = name
        deckRows[index].description = description
    }

    public func deleteDeck(_ id: DeckID) async throws {
        deckRows.removeAll { $0.id == id }
        noteRows.removeAll { $0.deckID == id }
    }

    public func reorderDecks(in folder: FolderID, ids: [DeckID]) async throws {
        for (offset, id) in ids.enumerated() {
            guard let index = deckRows.firstIndex(where: { $0.id == id }) else { throw FakeCatalogError.notFound }
            deckRows[index].position = offset + 1
        }
    }

    public func moveDeck(_ id: DeckID, to folder: FolderID) async throws {
        guard let index = deckRows.firstIndex(where: { $0.id == id }) else { throw FakeCatalogError.notFound }
        deckRows[index].folderID = folder
        deckRows[index].position = deckRows.filter { $0.folderID == folder }.count + 1
    }

    public func noteTypes() async throws -> [NoteType] {
        typeRows
    }

    public func notes(in deck: DeckID, query: NoteQuery) async throws -> NotePage {
        var rows = noteRows.filter { $0.deckID == deck }
        if !query.text.isEmpty {
            let needle = query.text.lowercased()
            rows = rows.filter { row in
                row.fields.contains { $0.value.lowercased().contains(needle) }
            }
        }
        rows.sort { $0.id.rawValue < $1.id.rawValue }
        let total = rows.count
        let start = min(max(query.offset, 0), rows.count)
        let end = min(start + max(query.limit, 1), rows.count)
        return NotePage(notes: Array(rows[start..<end]), total: total)
    }

    public func createNote(in deck: DeckID, values: [NoteFieldValue]) async throws -> NoteID {
        guard let type = typeRows.first else { throw FakeCatalogError.notFound }
        let termID = type.fields.first { $0.role == .term }?.id ?? ""
        let term = values.first { $0.fieldID == termID }?.value.trimmingCharacters(in: .whitespaces) ?? ""
        if term.isEmpty { throw FakeCatalogError.invalid }
        let id = NoteID(rawValue: "n\(takeID())")
        noteRows.append(Note(id: id, deckID: deck, fields: values, state: .new))
        return id
    }

    public func updateNote(_ id: NoteID, values: [NoteFieldValue]) async throws {
        guard let index = noteRows.firstIndex(where: { $0.id == id }) else { throw FakeCatalogError.notFound }
        noteRows[index].fields = values
    }

    public func deleteNote(_ id: NoteID) async throws {
        noteRows.removeAll { $0.id == id }
    }

    public func duplicate(in deck: DeckID, term: String) async throws -> DuplicateTerm {
        let type = typeRows.first
        let termID = type?.fields.first { $0.role == .term }?.id ?? ""
        let meaningID = type?.fields.first { $0.role == .meaning }?.id ?? ""
        let needle = term.trimmingCharacters(in: .whitespaces)
        for row in noteRows where row.deckID == deck {
            if row.value(of: termID) == needle {
                return DuplicateTerm(exists: true, meaning: row.value(of: meaningID))
            }
        }
        return DuplicateTerm(exists: false, meaning: "")
    }

    private func takeID() -> Int {
        defer { nextID += 1 }
        return nextID
    }
}

public enum FakeCatalogError: Error, Equatable, Sendable {
    case notFound
    case invalid
}
