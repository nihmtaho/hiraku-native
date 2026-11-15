import HirakuModels
import SwiftUI

/// Entry point of the folder feature; the app builds the dependencies and owns the controller.
public enum FeatureFolders {
    @MainActor public static func makeController(
        folders: any FolderRepository,
        events: any ChangeEvents,
        clock: any AppClock
    ) -> FoldersController {
        FoldersController(folders: folders, events: events, clock: clock)
    }

    @MainActor public static func screen(
        controller: FoldersController,
        openFolder: @escaping (Folder) -> Void
    ) -> some View {
        FoldersView(controller: controller, openFolder: openFolder)
    }
}
