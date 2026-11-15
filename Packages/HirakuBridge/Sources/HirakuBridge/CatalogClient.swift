import Foundation
import HirakuModels

/// Maps catalog protocols onto the contract; features never touch proto messages.
public struct CatalogClient: FolderRepository, DeckRepository, NoteTypeRepository, NoteRepository, Sendable {
    private let call: any HirakuCalling
    private let clock: any AppClock

    public init(call: any HirakuCalling, clock: any AppClock) {
        self.call = call
        self.clock = clock
    }

    public func folders() async throws -> [Folder] {
        let request = Hiraku_V1_ListFoldersRequest()
        let response = try Hiraku_V1_ListFoldersResponse(serializedBytes: try await send(.listFolders, request.serializedData()))
        return response.folders.map(mapFolder)
    }

    public func createFolder(name: String) async throws -> FolderID {
        var request = Hiraku_V1_CreateFolderRequest()
        request.name = name
        request.nowMs = clock.nowMs
        let response = try Hiraku_V1_CreateFolderResponse(serializedBytes: try await send(.createFolder, request.serializedData()))
        return FolderID(rawValue: response.folderID)
    }

    public func renameFolder(_ id: FolderID, name: String) async throws {
        var request = Hiraku_V1_UpdateFolderRequest()
        request.folderID = id.rawValue
        request.name = name
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_UpdateFolderResponse(serializedBytes: try await send(.updateFolder, request.serializedData()))
    }

    public func deleteFolder(_ id: FolderID) async throws {
        var request = Hiraku_V1_DeleteFolderRequest()
        request.folderID = id.rawValue
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_DeleteFolderResponse(serializedBytes: try await send(.deleteFolder, request.serializedData()))
    }

    public func reorderFolders(_ ids: [FolderID]) async throws {
        var request = Hiraku_V1_ReorderFoldersRequest()
        request.folderIds = ids.map(\.rawValue)
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_ReorderFoldersResponse(serializedBytes: try await send(.reorderFolders, request.serializedData()))
    }

    public func decks(in folder: FolderID) async throws -> [Deck] {
        var request = Hiraku_V1_ListDecksRequest()
        request.folderID = folder.rawValue
        let response = try Hiraku_V1_ListDecksResponse(serializedBytes: try await send(.listDecks, request.serializedData()))
        return response.decks.map(mapDeck)
    }

    public func createDeck(
        in folder: FolderID,
        name: String,
        description: String,
        noteType: NoteTypeID?
    ) async throws -> DeckID {
        var request = Hiraku_V1_CreateDeckRequest()
        request.folderID = folder.rawValue
        request.name = name
        request.description_p = description
        request.noteTypeID = noteType?.rawValue ?? ""
        request.nowMs = clock.nowMs
        let response = try Hiraku_V1_CreateDeckResponse(serializedBytes: try await send(.createDeck, request.serializedData()))
        return DeckID(rawValue: response.deckID)
    }

    public func updateDeck(_ id: DeckID, name: String, description: String) async throws {
        var request = Hiraku_V1_UpdateDeckRequest()
        request.deckID = id.rawValue
        request.name = name
        request.description_p = description
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_UpdateDeckResponse(serializedBytes: try await send(.updateDeck, request.serializedData()))
    }

    public func deleteDeck(_ id: DeckID) async throws {
        var request = Hiraku_V1_DeleteDeckRequest()
        request.deckID = id.rawValue
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_DeleteDeckResponse(serializedBytes: try await send(.deleteDeck, request.serializedData()))
    }

    public func reorderDecks(in folder: FolderID, ids: [DeckID]) async throws {
        var request = Hiraku_V1_ReorderDecksRequest()
        request.folderID = folder.rawValue
        request.deckIds = ids.map(\.rawValue)
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_ReorderDecksResponse(serializedBytes: try await send(.reorderDecks, request.serializedData()))
    }

    public func moveDeck(_ id: DeckID, to folder: FolderID) async throws {
        var request = Hiraku_V1_MoveDeckRequest()
        request.deckID = id.rawValue
        request.targetFolderID = folder.rawValue
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_MoveDeckResponse(serializedBytes: try await send(.moveDeck, request.serializedData()))
    }

    public func noteTypes() async throws -> [NoteType] {
        let request = Hiraku_V1_ListNoteTypesRequest()
        let response = try Hiraku_V1_ListNoteTypesResponse(
            serializedBytes: try await send(.listNoteTypes, request.serializedData())
        )
        return response.noteTypes.map(mapNoteType)
    }

    public func notes(in deck: DeckID, query: NoteQuery) async throws -> NotePage {
        var request = Hiraku_V1_ListNotesRequest()
        request.deckID = deck.rawValue
        request.query = query.text
        request.limit = Int32(query.limit)
        request.offset = Int32(query.offset)
        let response = try Hiraku_V1_ListNotesResponse(serializedBytes: try await send(.listNotes, request.serializedData()))
        return NotePage(notes: response.notes.map(mapNote), total: Int(response.total))
    }

    public func createNote(in deck: DeckID, values: [NoteFieldValue]) async throws -> NoteID {
        var request = Hiraku_V1_CreateNoteRequest()
        request.deckID = deck.rawValue
        request.fields = values.map { protoField($0) }
        request.nowMs = clock.nowMs
        let response = try Hiraku_V1_CreateNoteResponse(serializedBytes: try await send(.createNote, request.serializedData()))
        return NoteID(rawValue: response.noteID)
    }

    public func updateNote(_ id: NoteID, values: [NoteFieldValue]) async throws {
        var request = Hiraku_V1_UpdateNoteRequest()
        request.noteID = id.rawValue
        request.fields = values.map { protoField($0) }
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_UpdateNoteResponse(serializedBytes: try await send(.updateNote, request.serializedData()))
    }

    public func deleteNote(_ id: NoteID) async throws {
        var request = Hiraku_V1_DeleteNoteRequest()
        request.noteID = id.rawValue
        request.nowMs = clock.nowMs
        _ = try Hiraku_V1_DeleteNoteResponse(serializedBytes: try await send(.deleteNote, request.serializedData()))
    }

    public func duplicate(in deck: DeckID, term: String) async throws -> DuplicateTerm {
        var request = Hiraku_V1_CheckDuplicateRequest()
        request.deckID = deck.rawValue
        request.term = term
        let response = try Hiraku_V1_CheckDuplicateResponse(serializedBytes: try await send(.checkDuplicate, request.serializedData()))
        return DuplicateTerm(exists: response.exists, meaning: response.meaning)
    }

    private func send(_ method: Hiraku_V1_Method, _ request: Data = Data()) async throws -> Data {
        try await call.call(method, request: request)
    }

    private func mapFolder(_ folder: Hiraku_V1_Folder) -> Folder {
        Folder(
            id: FolderID(rawValue: folder.id),
            name: folder.name,
            position: Int(folder.position),
            deckCount: Int(folder.deckCount),
            noteCount: Int(folder.noteCount)
        )
    }

    private func mapDeck(_ deck: Hiraku_V1_Deck) -> Deck {
        Deck(
            id: DeckID(rawValue: deck.id),
            folderID: FolderID(rawValue: deck.folderID),
            name: deck.name,
            description: deck.description_p,
            position: Int(deck.position),
            noteTypeID: NoteTypeID(rawValue: deck.noteTypeID),
            noteCount: Int(deck.noteCount),
            stateCounts: StateCounts(
                new: Int(deck.stateNewCount),
                learning: Int(deck.stateLearningCount),
                known: Int(deck.stateKnownCount)
            )
        )
    }

    private func mapNoteType(_ noteType: Hiraku_V1_NoteType) -> NoteType {
        NoteType(
            id: NoteTypeID(rawValue: noteType.id),
            name: noteType.name,
            isSystem: noteType.isSystem,
            fields: noteType.fields.map { field in
                NoteTypeField(
                    id: field.id,
                    role: FieldRole(rawValue: field.role) ?? .text,
                    name: field.name,
                    ord: Int(field.ord),
                    inputKind: InputKind(rawValue: field.inputKind) ?? .text,
                    required: field.required,
                    searchable: field.searchable
                )
            },
            frontFieldIDs: noteType.frontFieldIds,
            backFieldIDs: noteType.backFieldIds,
            typingAnswerFieldID: noteType.typingAnswerFieldID.isEmpty ? nil : noteType.typingAnswerFieldID
        )
    }

    private func mapNote(_ note: Hiraku_V1_Note) -> Note {
        Note(
            id: NoteID(rawValue: note.id),
            deckID: DeckID(rawValue: note.deckID),
            fields: note.fields.map { NoteFieldValue(fieldID: $0.fieldID, value: $0.value) },
            state: Self.mapState(note.state)
        )
    }

    private static func mapState(_ state: Hiraku_V1_NoteState) -> NoteState {
        switch state {
        case .learning: .learning
        case .known: .known
        default: .new
        }
    }

    private func protoField(_ value: NoteFieldValue) -> Hiraku_V1_FieldValue {
        var field = Hiraku_V1_FieldValue()
        field.fieldID = value.fieldID
        field.value = value.value
        return field
    }
}
