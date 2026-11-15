import DesignSystem
import HirakuModels
import SwiftUI

/// Deck list of one folder with create, edit, move, delete and the accessible reorder.
public struct DecksView: View {
    private let controller: DecksController
    private let onBack: () -> Void
    private let openDeck: (Deck) -> Void

    @State private var sheet: DeckSheetMode?
    @State private var pendingDeletion: Deck?

    public init(controller: DecksController, onBack: @escaping () -> Void, openDeck: @escaping (Deck) -> Void) {
        self.controller = controller
        self.onBack = onBack
        self.openDeck = openDeck
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(controller.folder.name)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: onBack) {
                            AppIcon.chevronBack.image
                        }
                        .accessibilityLabel(Text("common.back"))
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            sheet = .create
                        } label: {
                            AppIcon.add.image
                        }
                        .accessibilityLabel(Text("decks.add"))
                    }
                }
                .sheet(item: $sheet) { mode in
                    DeckFormSheet(
                        mode: mode,
                        noteTypeName: controller.defaultNoteType?.name,
                        isSaving: controller.isSaving,
                        onSave: { name, description in
                            switch mode {
                            case .create:
                                guard await controller.create(name: name, description: description) else { return false }
                            case .edit(let deck):
                                guard await controller.update(deck, name: name, description: description) else { return false }
                            }
                            sheet = nil
                            return true
                        }
                    )
                }
                .confirmationDialog(
                    Text("decks.delete.title \(pendingDeletion?.name ?? "")"),
                    isPresented: Binding(
                        get: { pendingDeletion != nil },
                        set: { if !$0 { pendingDeletion = nil } }
                    ),
                    presenting: pendingDeletion
                ) { deck in
                    Button(role: .destructive) {
                        Task { await controller.delete(deck) }
                        pendingDeletion = nil
                    } label: {
                        Text("delete")
                    }
                } message: { deck in
                    Text("decks.delete.message \(deck.noteCount)")
                }
                .alert(
                    Text("error.generic.title"),
                    isPresented: Binding(
                        get: { controller.lastError != nil },
                        set: { if !$0 { controller.clearError() } }
                    )
                ) {
                    Button("common.close", role: .cancel) { controller.clearError() }
                } message: {
                    Text(LocalizedStringKey(controller.lastError ?? "error.generic.message"))
                }
        }
        .task { controller.start() }
        .onDisappear { controller.stop() }
    }

    @ViewBuilder
    private var content: some View {
        switch controller.phase {
        case .loading:
            ProgressView()
        case .failed:
            ContentUnavailableView {
                Text("error.generic.title")
            } description: {
                Text("error.generic.message")
            } actions: {
                HKButton("common.retry") {
                    Task { await controller.load() }
                }
            }
        case .ready where controller.rows.isEmpty:
            emptyState
        case .ready:
            list
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text("decks.empty.title")
            } icon: {
                AppIcon.decks.image
            }
        } description: {
            Text("decks.empty.message")
        } actions: {
            HKButton("decks.empty.cta") {
                sheet = .create
            }
        }
    }

    private var list: some View {
        List(controller.rows) { deck in
            Button {
                openDeck(deck)
            } label: {
                VStack(alignment: .leading, spacing: HKSpacing.xs) {
                    Text(deck.name)
                        .font(HKFont.bodyMD.font())
                        .foregroundStyle(HKColor.primary)
                    Text("common.wordCount \(deck.noteCount)")
                        .font(HKFont.bodySM.font())
                        .foregroundStyle(HKColor.secondary)
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("edit") { sheet = .edit(deck) }
                if controller.canMove {
                    Menu("move") {
                        ForEach(controller.otherFolders) { folder in
                            Button(folder.name) {
                                Task { await controller.move(deck, to: folder) }
                            }
                        }
                    }
                } else {
                    Button("decks.move.disabledHint") {}
                        .disabled(true)
                }
                Button("folders.menu.moveUp") {
                    Task { await controller.reorder(deck, up: true) }
                }
                .disabled(controller.rows.first?.id == deck.id)
                Button("folders.menu.moveDown") {
                    Task { await controller.reorder(deck, up: false) }
                }
                .disabled(controller.rows.last?.id == deck.id)
                Divider()
                Button("delete", role: .destructive) { pendingDeletion = deck }
            }
        }
    }
}

/// Create and edit share one sheet; the note type is fixed once the deck exists.
private struct DeckFormSheet: View {
    let mode: DeckSheetMode
    let noteTypeName: String?
    let isSaving: Bool
    let onSave: (String, String) async -> Bool

    @State private var name: String
    @State private var details: String
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    init(mode: DeckSheetMode, noteTypeName: String?, isSaving: Bool, onSave: @escaping (String, String) async -> Bool) {
        self.mode = mode
        self.noteTypeName = noteTypeName
        self.isSaving = isSaving
        self.onSave = onSave
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _details = State(initialValue: "")
        case .edit(let deck):
            _name = State(initialValue: deck.name)
            _details = State(initialValue: deck.description)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HKSpacing.lg) {
            Text(title)
                .font(HKFont.h2.font())
            HKField(
                "decks.name.label",
                placeholder: "folders.name.placeholder",
                text: $name,
                error: errorText
            )
            .focused($focused)
            HKField("decks.description.label", placeholder: "decks.description.label", text: $details)
            if let noteTypeName {
                VStack(alignment: .leading, spacing: HKSpacing.xs) {
                    Text("decks.noteType.label")
                        .font(HKFont.labelCaps.font())
                        .tracking(HKFont.labelCaps.tracking())
                        .textCase(.uppercase)
                        .foregroundStyle(HKColor.secondary)
                    Text(verbatim: noteTypeName)
                        .font(HKFont.bodyMD.font())
                        .foregroundStyle(HKColor.primary)
                    if case .edit = mode {
                        Text("decks.noteType.locked")
                            .font(HKFont.bodySM.font())
                            .foregroundStyle(HKColor.secondary)
                    }
                }
            }
            HStack {
                Button("cancel") { dismiss() }
                Spacer()
                HKButton("common.save") {
                    Task {
                        if await onSave(name, details) { dismiss() }
                    }
                }
                .disabled(isSaving || DecksController.validate(name: name) != nil)
            }
        }
        .padding(HKSpacing.xl)
        .frame(minWidth: 320, maxWidth: 420)
        .onAppear { focused = true }
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .create: "decks.create.title"
        case .edit: "decks.edit.title"
        }
    }

    private var errorText: LocalizedStringKey? {
        switch DecksController.validate(name: name) {
        case .empty: "folders.name.error.empty"
        case .tooLong: "folders.name.error.tooLong"
        case nil: nil
        }
    }
}

enum DeckSheetMode: Identifiable {
    case create
    case edit(Deck)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let deck): deck.id.rawValue
        }
    }
}
