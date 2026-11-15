import Foundation
import HirakuModels

/// Drives one folder's deck list: load, create, edit, delete, move and the accessible reorder.
@MainActor @Observable
public final class DecksController {
    public private(set) var rows: [Deck] = []
    public private(set) var folders: [Folder] = []
    public private(set) var noteTypes: [NoteType] = []
    public private(set) var phase: LoadPhase = .loading
    public private(set) var lastError: String?
    public private(set) var isSaving = false

    public let folder: Folder

    private let decks: any DeckRepository
    private let folderRepository: any FolderRepository
    private let types: any NoteTypeRepository
    private let events: any ChangeEvents
    private var listener: Task<Void, Never>?

    public init(
        folder: Folder,
        decks: any DeckRepository,
        folders: any FolderRepository,
        noteTypes: any NoteTypeRepository,
        events: any ChangeEvents
    ) {
        self.folder = folder
        self.decks = decks
        self.folderRepository = folders
        self.types = noteTypes
        self.events = events
    }

    public func start() {
        listener = Task { [weak self] in
            await self?.load()
            guard let stream = self?.events.changes() else { return }
            for await _ in stream {
                await self?.load()
            }
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    public func load() async {
        do {
            rows = try await decks.decks(in: folder.id)
            folders = try await folderRepository.folders()
            noteTypes = try await types.noteTypes()
            phase = .ready
        } catch {
            phase = .failed
            lastError = "error.generic.message"
        }
    }

    public var defaultNoteType: NoteType? {
        noteTypes.first { $0.isSystem } ?? noteTypes.first
    }

    public var canMove: Bool {
        folders.count > 1
    }

    public var otherFolders: [Folder] {
        folders.filter { $0.id != folder.id }
    }

    public static func validate(name: String) -> NameError? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.count > 100 { return .tooLong }
        return nil
    }

    @discardableResult
    public func create(name: String, description: String) async -> Bool {
        guard DecksController.validate(name: name) == nil else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await decks.createDeck(
                in: folder.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                noteType: defaultNoteType?.id
            )
            await load()
            return true
        } catch {
            lastError = "error.save.failed"
            return false
        }
    }

    @discardableResult
    public func update(_ deck: Deck, name: String, description: String) async -> Bool {
        guard DecksController.validate(name: name) == nil else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await decks.updateDeck(
                deck.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await load()
            return true
        } catch {
            lastError = "error.save.failed"
            return false
        }
    }

    public func delete(_ deck: Deck) async {
        do {
            try await decks.deleteDeck(deck.id)
            await load()
        } catch {
            lastError = "error.generic.message"
        }
    }

    public func move(_ deck: Deck, to target: Folder) async {
        do {
            try await decks.moveDeck(deck.id, to: target.id)
            await load()
        } catch {
            lastError = "error.generic.message"
        }
    }

    public func reorder(_ deck: Deck, up: Bool) async {
        guard let index = rows.firstIndex(where: { $0.id == deck.id }) else { return }
        let target = up ? index - 1 : index + 1
        guard rows.indices.contains(target) else { return }
        var reordered = rows
        reordered.swapAt(index, target)
        do {
            try await decks.reorderDecks(in: folder.id, ids: reordered.map(\.id))
            rows = reordered
        } catch {
            lastError = "error.generic.message"
        }
    }

    /// `List.onMove` lands here; the whole order is persisted in one call.
    public func moveRows(from source: IndexSet, to destination: Int) async {
        var reordered = rows
        reordered.move(fromOffsets: source, toOffset: destination)
        do {
            try await decks.reorderDecks(in: folder.id, ids: reordered.map(\.id))
            rows = reordered
        } catch {
            lastError = "error.generic.message"
        }
    }

    public func clearError() {
        lastError = nil
    }
}
