import Foundation
import HirakuModels

/// Drives the folder list: load, create, rename, delete and the accessible reorder.
@MainActor @Observable
public final class FoldersController {
    public private(set) var rows: [Folder] = []
    public private(set) var phase: LoadPhase = .loading
    public private(set) var lastError: String?
    public private(set) var isSaving = false

    private let folders: any FolderRepository
    private let events: any ChangeEvents
    private let clock: any AppClock
    private var listener: Task<Void, Never>?

    public init(folders: any FolderRepository, events: any ChangeEvents, clock: any AppClock) {
        self.folders = folders
        self.events = events
        self.clock = clock
    }

    /// Loads once and again whenever the core reports a change; no I/O before this call.
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
            rows = try await folders.folders()
            phase = .ready
        } catch {
            phase = .failed
            lastError = "error.generic.message"
        }
    }

    public static func validate(name: String) -> NameError? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.count > 100 { return .tooLong }
        return nil
    }

    @discardableResult
    public func create(name: String) async -> Bool {
        guard FoldersController.validate(name: name) == nil else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await folders.createFolder(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            await load()
            return true
        } catch {
            lastError = "error.save.failed"
            return false
        }
    }

    @discardableResult
    public func rename(_ folder: Folder, to name: String) async -> Bool {
        guard FoldersController.validate(name: name) == nil else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await folders.renameFolder(folder.id, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            await load()
            return true
        } catch {
            lastError = "error.save.failed"
            return false
        }
    }

    public func delete(_ folder: Folder) async {
        do {
            try await folders.deleteFolder(folder.id)
            await load()
        } catch {
            lastError = "error.generic.message"
        }
    }

    /// Moves one folder up or down and persists the whole order.
    public func move(_ folder: Folder, up: Bool) async {
        guard let index = rows.firstIndex(where: { $0.id == folder.id }) else { return }
        let target = up ? index - 1 : index + 1
        guard rows.indices.contains(target) else { return }
        var reordered = rows
        reordered.swapAt(index, target)
        do {
            try await folders.reorderFolders(reordered.map(\.id))
            rows = reordered
        } catch {
            lastError = "error.generic.message"
        }
    }

    public func clearError() {
        lastError = nil
    }
}
