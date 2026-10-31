import CoreText
import SwiftUI

enum NotoFont {
    static let regular = "NotoSansJP-Regular"

    // Runtime registration works the same on iOS and macOS, unlike per-platform Info.plist keys.
    @discardableResult
    static func register() -> Bool {
        guard let url = Bundle.main.url(forResource: regular, withExtension: "ttf") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static var isResolved: Bool {
        let font = CTFontCreateWithName(regular as CFString, 12, nil)
        return CTFontCopyFamilyName(font) as String == "Noto Sans JP"
    }
}
