import Foundation
import HirakuModels

/// Drives the word list of one deck: paged load, debounced search, delete and change reloads.
@MainActor @Observable
public final class WordListController {
    public private(set) var rows: [Note] = []
    public private(set) var total = 0
    public private(set) var phase: LoadPhase = .loading
    public private(set) var lastError: String?
    public private(set) var noteType: NoteType?

    public var searchText = "" {
        didSet { scheduleSearch() }
    }

    public let deck: Deck

    private let notes: any NoteRepository
    private let types: any NoteTypeRepository
    private let events: any ChangeEvents
    private let clock: any AppClock
    private var listener: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    public init(
        deck: Deck,
        notes: any NoteRepository,
        noteTypes: any NoteTypeRepository,
        events: any ChangeEvents,
        clock: any AppClock
    ) {
        self.deck = deck
        self.notes = notes
        self.types = noteTypes
        self.events = events
        self.clock = clock
    }

    public func start() {
        listener = Task { [weak self] in
            await self?.loadNoteType()
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
        searchTask?.cancel()
        searchTask = nil
    }

    public func load() async {
        do {
            let page = try await notes.notes(in: deck.id, query: NoteQuery(text: searchText))
            rows = page.notes
            total = page.total
            phase = .ready
        } catch {
            phase = .failed
            lastError = "error.generic.message"
        }
    }

    public func loadNoteType() async {
        guard noteType == nil else { return }
        do {
            noteType = try await types.noteTypes().first { $0.id == deck.noteTypeID }
        } catch {
            lastError = "error.generic.message"
        }
    }

    public func clearFilter() async {
        searchText = ""
        searchTask?.cancel()
        await load()
    }

    public func delete(_ note: Note) async {
        do {
            try await notes.deleteNote(note.id)
            await load()
        } catch {
            lastError = "error.generic.message"
        }
    }

    public func clearError() {
        lastError = nil
    }

    /// One debounce window of the app clock; typing again cancels the previous wait.
    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            await clock.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await load()
        }
    }
}
