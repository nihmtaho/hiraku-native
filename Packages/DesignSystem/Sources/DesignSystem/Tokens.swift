import CoreText
import Foundation
import SwiftUI

/// Raw sRGB values, the single source of the colour tokens and of the contrast tests.
enum HKHex {
    static let primary: UInt32 = 0x16130F
    static let secondary: UInt32 = 0x6B655C
    static let tertiary: UInt32 = 0xFF4D2E
    static let tertiaryHover: UInt32 = 0xE83F1F
    static let tertiaryContainer: UInt32 = 0xFFE9E3
    static let onTertiary: UInt32 = 0xFFFFFF
    static let neutral: UInt32 = 0xF4F1EA
    static let surface: UInt32 = 0xFFFDF8
    static let onPrimary: UInt32 = 0xF4F1EA
    static let border: UInt32 = 0x16130F
    static let borderSoft: UInt32 = 0xDED8CC
    static let divider: UInt32 = 0xE8E3D9
    static let faint: UInt32 = 0xA39C8F
    static let stateNew: UInt32 = 0x3A6EA5
    static let stateLearning: UInt32 = 0xD9A300
    static let stateLearningInk: UInt32 = 0xA67C00
    static let stateKnown: UInt32 = 0x2F9E6F
    static let kanaFill: UInt32 = 0xF0F8F4
}

/// Colours of `docs/product/DESIGN.md` §Colors, one fixed light appearance.
public enum HKColor {
    public static let primary = Color(hex: HKHex.primary)
    public static let secondary = Color(hex: HKHex.secondary)
    public static let tertiary = Color(hex: HKHex.tertiary)
    public static let tertiaryHover = Color(hex: HKHex.tertiaryHover)
    public static let tertiaryContainer = Color(hex: HKHex.tertiaryContainer)
    public static let onTertiary = Color(hex: HKHex.onTertiary)
    public static let neutral = Color(hex: HKHex.neutral)
    public static let surface = Color(hex: HKHex.surface)
    public static let onPrimary = Color(hex: HKHex.onPrimary)
    public static let border = Color(hex: HKHex.border)
    public static let borderSoft = Color(hex: HKHex.borderSoft)
    public static let divider = Color(hex: HKHex.divider)
    public static let faint = Color(hex: HKHex.faint)
    public static let stateNew = Color(hex: HKHex.stateNew)
    public static let stateLearning = Color(hex: HKHex.stateLearning)
    public static let stateLearningInk = Color(hex: HKHex.stateLearningInk)
    public static let stateKnown = Color(hex: HKHex.stateKnown)
    public static let kanaFill = Color(hex: HKHex.kanaFill)
}

/// One typography token: the platform size, the tracking in points and the scaled font.
public struct HKTextStyle: Sendable {
    public let size: CGFloat
    public let tracking: CGFloat
    public let font: Font
}

/// Typography of `docs/product/DESIGN.md` §Typography.
public enum HKFont {
    public static let jpFamily = "NotoSansJP-Regular"

    public static let display = style("Georgia", phone: 40, mac: 56, tracking: -0.02, relativeTo: .largeTitle)
    public static let h1 = style("Georgia", phone: 30, mac: 34, tracking: -0.02, relativeTo: .title)
    public static let h2 = style("Georgia", phone: 22, mac: 24, tracking: -0.02, relativeTo: .title2)
    public static let jpHero = style(jpFamily, phone: 72, mac: 88, tracking: -0.03)
    public static let jpTerm = style(jpFamily, phone: 20, mac: 18, tracking: -0.01, relativeTo: .title3)
    public static let bodyMD = style("Helvetica Neue", phone: 15, mac: 13, tracking: 0, relativeTo: .body)
    public static let bodySM = style("Helvetica Neue", phone: 13, mac: 11, tracking: 0, relativeTo: .footnote)
    public static let labelCaps = style("Helvetica Neue", phone: 11, mac: 11, tracking: 0.2, relativeTo: .caption)
    public static let eyebrow = style("Helvetica Neue", phone: 12, mac: 11, tracking: 0.24, relativeTo: .caption)
    public static let button = style("Helvetica Neue", phone: 15, mac: 13, tracking: 0.01, relativeTo: .headline)

    /// Registers the bundled Noto Sans JP subset; runtime registration works the same on iOS and macOS.
    @discardableResult
    public static func registerBundledFonts() -> Bool {
        guard let url = Bundle.module.url(
            forResource: jpFamily,
            withExtension: "ttf",
            subdirectory: "Resources"
        ) else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    private static func style(
        _ family: String,
        phone: CGFloat,
        mac: CGFloat,
        tracking: CGFloat,
        relativeTo textStyle: Font.TextStyle? = nil
    ) -> HKTextStyle {
        #if os(macOS)
        let size = mac
        #else
        let size = phone
        #endif
        let font = textStyle.map { Font.custom(family, size: size, relativeTo: $0) }
            ?? Font.custom(family, size: size)
        return HKTextStyle(size: size, tracking: tracking * size, font: font)
    }
}

/// Spacing scale in points; the uneven web paddings are normalised onto it.
public enum HKSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 18
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 40
}

/// Corner radii for `RoundedRectangle(style: .continuous)`; a pill is `Capsule()`.
public enum HKRadius {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
}

public enum HKBorder {
    public static let width: CGFloat = 1.5
    public static let hairline: CGFloat = 1
}

public enum HKHitTarget {
    public static let touchMin: CGFloat = 44
    public static let pointerMin: CGFloat = 28
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
