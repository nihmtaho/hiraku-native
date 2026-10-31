#if DEBUG
import SwiftUI

// Debug-only S-6 check: bundled Noto Sans JP next to the system fallback.
// Spike shell keeps plain strings; String Catalog and COPY come with product UI.
struct FontCheckView: View {
    private let sample = "開 食べる 漢字 ひらがな カタカナ 憂鬱 薔薇 ー、。"

    var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: "S-6 font check — Noto resolved: \(NotoFont.isResolved)")
                .font(.caption)
            Text(verbatim: "開")
                .font(.custom(NotoFont.regular, size: 72))
            Text(verbatim: sample)
                .font(.custom(NotoFont.regular, size: 20))
            Text(verbatim: sample)
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
        }
    }
}
#endif
