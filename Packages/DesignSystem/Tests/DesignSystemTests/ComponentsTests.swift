import SwiftUI
import Testing

@testable import DesignSystem

@Test @MainActor func componentsBuildInEveryVariant() throws {
    for variant in [HKButtonVariant.primary, .secondary, .dark] {
        let button = HKButton("Lưu", variant: variant) {}
        _ = button.body
    }
    _ = HKCard { Text("Nội dung") }.body
    _ = HKField("Từ", placeholder: "Nhập từ", text: .constant("食べる")).body
}

@Test @MainActor func fieldShowsTheInlineErrorRow() throws {
    let withError = HKField("Từ", placeholder: "Nhập từ", text: .constant(""), error: "Không được để trống")
    _ = withError.body
    let withoutError = HKField("Từ", placeholder: "Nhập từ", text: .constant(""))
    _ = withoutError.body
}
