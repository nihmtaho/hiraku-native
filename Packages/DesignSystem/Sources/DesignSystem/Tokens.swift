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

/// The phone / pad / mac column of a typography token.
public enum HKSizeClass: Sendable {
    case phone
    case pad
    case mac

    /// Column for the current platform; an iPad caller passes `.pad` from a regular width.
    public static var current: HKSizeClass {
        #if os(macOS)
        .mac
        #else
        .phone
        #endif
    }
}

/// One typography token: the three column sizes, the weight, the tracking and the line height.
public struct HKTextStyle: Sendable {
    public let phone: CGFloat
    public let pad: CGFloat
    public let mac: CGFloat
    public let weight: Font.Weight
    public let trackingEm: CGFloat
    public let lineHeight: CGFloat

    private let family: String
    private let relativeTo: Font.TextStyle?

    public func size(_ sizeClass: HKSizeClass = .current) -> CGFloat {
        switch sizeClass {
        case .phone: phone
        case .pad: pad
        case .mac: mac
        }
    }

    public func tracking(_ sizeClass: HKSizeClass = .current) -> CGFloat {
        trackingEm * size(sizeClass)
    }

    public func lineSpacing(_ sizeClass: HKSizeClass = .current) -> CGFloat {
        (lineHeight - 1) * size(sizeClass)
    }

    /// A style without a Dynamic Type anchor keeps its size; `jp-hero` self-shrinks in the view.
    public func font(_ sizeClass: HKSizeClass = .current) -> Font {
        let pointSize = size(sizeClass)
        let font: Font = if let relativeTo {
            Font.custom(family, size: pointSize, relativeTo: relativeTo)
        } else {
            Font.custom(family, fixedSize: pointSize)
        }
        return font.weight(weight)
    }

    init(
        family: String,
        phone: CGFloat,
        pad: CGFloat,
        mac: CGFloat,
        weight: Font.Weight,
        trackingEm: CGFloat,
        lineHeight: CGFloat,
        relativeTo: Font.TextStyle? = nil
    ) {
        self.family = family
        self.phone = phone
        self.pad = pad
        self.mac = mac
        self.weight = weight
        self.trackingEm = trackingEm
        self.lineHeight = lineHeight
        self.relativeTo = relativeTo
    }
}

/// Typography of `docs/product/DESIGN.md` §Typography.
public enum HKFont {
    public static let jpFamily = "NotoSansJP-Regular"

    public static let display = HKTextStyle(
        family: "Georgia", phone: 40, pad: 56, mac: 56,
        weight: .regular, trackingEm: -0.02, lineHeight: 1.0, relativeTo: .largeTitle
    )
    public static let h1 = HKTextStyle(
        family: "Georgia", phone: 30, pad: 34, mac: 34,
        weight: .regular, trackingEm: -0.02, lineHeight: 1.05, relativeTo: .title
    )
    public static let h2 = HKTextStyle(
        family: "Georgia", phone: 22, pad: 24, mac: 24,
        weight: .regular, trackingEm: -0.02, lineHeight: 1.1, relativeTo: .title2
    )
    public static let jpHero = HKTextStyle(
        family: jpFamily, phone: 72, pad: 88, mac: 88,
        weight: .regular, trackingEm: -0.03, lineHeight: 1.1
    )
    public static let jpTerm = HKTextStyle(
        family: jpFamily, phone: 20, pad: 20, mac: 18,
        weight: .regular, trackingEm: -0.01, lineHeight: 1.2, relativeTo: .title3
    )
    public static let bodyMD = HKTextStyle(
        family: "Helvetica Neue", phone: 15, pad: 15, mac: 13,
        weight: .regular, trackingEm: 0, lineHeight: 1.45, relativeTo: .body
    )
    public static let bodySM = HKTextStyle(
        family: "Helvetica Neue", phone: 13, pad: 13, mac: 11,
        weight: .regular, trackingEm: 0, lineHeight: 1.4, relativeTo: .footnote
    )
    public static let labelCaps = HKTextStyle(
        family: "Helvetica Neue", phone: 11, pad: 11, mac: 11,
        weight: .bold, trackingEm: 0.2, lineHeight: 1.0, relativeTo: .caption
    )
    public static let eyebrow = HKTextStyle(
        family: "Helvetica Neue", phone: 12, pad: 12, mac: 11,
        weight: .bold, trackingEm: 0.24, lineHeight: 1.0, relativeTo: .caption
    )
    public static let button = HKTextStyle(
        family: "Helvetica Neue", phone: 15, pad: 15, mac: 15,
        weight: .bold, trackingEm: 0.01, lineHeight: 1.0, relativeTo: .headline
    )

    /// Registers the bundled Noto Sans JP subset; the app calls this at launch.
    @discardableResult
    public static func registerBundledFonts() -> Bool {
        guard let url = Bundle.module.url(
            forResource: jpFamily,
            withExtension: "ttf",
            subdirectory: "Resources"
        ) else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
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
    /// Increase Contrast draws the ink border heavier instead of adding colour.
    public static let increased: CGFloat = 2
}

public enum HKHitTarget {
    public static let touchMin: CGFloat = 44
    public static let pointerMin: CGFloat = 28
}

/// Control heights that differ from the minimum hit target.
public enum HKControl {
    public static let buttonTouch: CGFloat = 44
    public static let buttonPointer: CGFloat = 32
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
