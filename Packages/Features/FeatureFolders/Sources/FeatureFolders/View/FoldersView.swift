import DesignSystem
import HirakuModels
import SwiftUI

/// Folder list with the empty state, the create and rename sheet and the delete confirmation.
public struct FoldersView: View {
    private let controller: FoldersController
    private let openFolder: (Folder) -> Void

    @State private var sheet: FolderSheetMode?
    @State private var pendingDeletion: Folder?

    public init(controller: FoldersController, openFolder: @escaping (Folder) -> Void) {
        self.controller = controller
        self.openFolder = openFolder
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text(verbatim: "hiraku"))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            sheet = .create
                        } label: {
                            AppIcon.add.image
                        }
                        .accessibilityLabel(Text("folders.add"))
                    }
                }
                .sheet(item: $sheet) { mode in
                    FolderNameSheet(
                        mode: mode,
                        controller: controller,
                        onSave: { name in
                            switch mode {
                            case .create:
                                guard await controller.create(name: name) else { return false }
                            case .rename(let folder):
                                guard await controller.rename(folder, to: name) else { return false }
                            }
                            sheet = nil
                            return true
                        }
                    )
                }
                .confirmationDialog(
                    Text("folders.delete.title \(pendingDeletion?.name ?? "")"),
                    isPresented: Binding(
                        get: { pendingDeletion != nil },
                        set: { if !$0 { pendingDeletion = nil } }
                    ),
                    presenting: pendingDeletion
                ) { folder in
                    Button(role: .destructive) {
                        Task { await controller.delete(folder) }
                        pendingDeletion = nil
                    } label: {
                        Text("delete")
                    }
                } message: { folder in
                    Text("folders.delete.message \(folder.deckCount) \(folder.noteCount)")
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
            grid
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text("home.empty.title")
            } icon: {
                AppIcon.folder.image
            }
        } description: {
            Text("home.empty.message")
        } actions: {
            HKButton("home.empty.cta") {
                sheet = .create
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: HKSpacing.md)], spacing: HKSpacing.md) {
                ForEach(Array(controller.rows.enumerated()), id: \.element.id) { index, folder in
                    Button {
                        openFolder(folder)
                    } label: {
                        HKCard {
                            VStack(alignment: .leading, spacing: HKSpacing.xs) {
                                Text(folder.name)
                                    .font(HKFont.h2.font())
                                    .foregroundStyle(HKColor.primary)
                                Text("\(folder.deckCount) deck · \(folder.noteCount) từ")
                                    .font(HKFont.bodySM.font())
                                    .foregroundStyle(HKColor.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .draggable(folder.id.rawValue)
                    .dropDestination(for: String.self) { items, _ in
                        guard let dragged = items.first, let source = controller.rows.first(where: { $0.id.rawValue == dragged }) else {
                            return false
                        }
                        Task { await controller.move(source, toIndex: index) }
                        return true
                    }
                    .contextMenu {
                        Button("rename") { sheet = .rename(folder) }
                        Button("folders.menu.moveUp") {
                            Task { await controller.move(folder, up: true) }
                        }
                        .disabled(controller.rows.first?.id == folder.id)
                        Button("folders.menu.moveDown") {
                            Task { await controller.move(folder, up: false) }
                        }
                        .disabled(controller.rows.last?.id == folder.id)
                        Divider()
                        Button("delete", role: .destructive) { pendingDeletion = folder }
                    }
                }
            }
            .padding(HKSpacing.lg)
        }
    }
}

/// Create and rename share one sheet; it keeps the sheet open on an invalid name.
internal enum FolderSheetMode: Identifiable {
    case create
    case rename(Folder)

    var id: String {
        switch self {
        case .create: "create"
        case .rename(let folder): folder.id.rawValue
        }
    }
}

private struct FolderNameSheet: View {
    let mode: FolderSheetMode
    let controller: FoldersController
    let onSave: (String) async -> Bool

    @State private var name: String
    @State private var showDiscard = false
    @Environment(\.dismiss) private var dismiss

    init(mode: FolderSheetMode, controller: FoldersController, onSave: @escaping (String) async -> Bool) {
        self.mode = mode
        self.controller = controller
        self.onSave = onSave
        switch mode {
        case .create: _name = State(initialValue: "")
        case .rename(let folder): _name = State(initialValue: folder.name)
        }
    }

    private var initialName: String {
        switch mode {
        case .create: ""
        case .rename(let folder): folder.name
        }
    }

    private var hasChanges: Bool {
        name != initialName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HKSpacing.lg) {
            Text(title)
                .font(HKFont.h2.font())
            HKField(
                "folders.name.label",
                placeholder: "folders.name.placeholder",
                text: $name,
                error: errorText
            )
            HStack {
                Button("cancel") {
                    if hasChanges { showDiscard = true } else { dismiss() }
                }
                Spacer()
                HKButton("common.save") {
                    Task {
                        if await onSave(name) { dismiss() }
                    }
                }
                .disabled(controller.isSaving || FoldersController.validate(name: name) != nil)
            }
        }
        .padding(HKSpacing.xl)
        .frame(minWidth: 320, maxWidth: 420)
        .interactiveDismissDisabled(hasChanges)
        .confirmationDialog(Text("discard.title"), isPresented: $showDiscard) {
            Button("discard.confirm", role: .destructive) { dismiss() }
            Button("discard.cancel", role: .cancel) {}
        } message: {
            Text("discard.message")
        }
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .create: "folders.create.title"
        case .rename: "folders.rename.title"
        }
    }

    private var errorText: LocalizedStringKey? {
        switch FoldersController.validate(name: name) {
        case .empty: "folders.name.error.empty"
        case .tooLong: "folders.name.error.tooLong"
        case nil: nil
        }
    }
}
