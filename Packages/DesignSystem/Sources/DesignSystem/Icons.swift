import SwiftUI

/// SF Symbols of DESIGN §Iconography; features never spell a symbol name.
public enum AppIcon: CaseIterable, Sendable {
    case home
    case homeActive
    case stats
    case statsActive
    case settings
    case settingsActive
    case search
    case add
    case refresh
    case close
    case chevronBack
    case chevronForward
    case ellipsis
    case edit
    case delete
    case folder
    case decks
    case keyboard
    case skip
    case submit
    case backspace
    case correct
    case wrong

    public var systemName: String {
        switch self {
        case .home: "house"
        case .homeActive: "house.fill"
        case .stats: "chart.bar"
        case .statsActive: "chart.bar.fill"
        case .settings: "gearshape"
        case .settingsActive: "gearshape.fill"
        case .search: "magnifyingglass"
        case .add: "plus"
        case .refresh: "arrow.clockwise"
        case .close: "xmark"
        case .chevronBack: "chevron.left"
        case .chevronForward: "chevron.right"
        case .ellipsis: "ellipsis"
        case .edit: "pencil"
        case .delete: "trash"
        case .folder: "folder"
        case .decks: "rectangle.stack"
        case .keyboard: "keyboard"
        case .skip: "forward.end"
        case .submit: "return"
        case .backspace: "delete.left"
        case .correct: "checkmark"
        case .wrong: "xmark"
        }
    }

    public var image: Image {
        Image(systemName: systemName).symbolRenderingMode(.monochrome)
    }
}
