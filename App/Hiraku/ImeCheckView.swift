#if DEBUG
import SwiftUI

// Debug-only S-3 check: one real field mirrored into per-character cells.
// Spike shell keeps plain strings; String Catalog and COPY come with product UI.
struct ImeCheckView: View {
    @State private var text = ""
    @State private var isComposing = false
    @State private var submits = 0
    @State private var graded = ""
    private let probe = ImeProbe()

    var body: some View {
        VStack(spacing: 6) {
            KanaInputField(text: $text, isComposing: $isComposing, probe: probe) {
                submits += 1
                graded = text
            }
            .frame(height: 36)
            HStack(spacing: 4) {
                ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                    Text(String(ch))
                        .font(.custom(NotoFont.regular, size: 20))
                        .frame(width: 28, height: 36)
                        .background(isComposing ? Color.yellow.opacity(0.3) : Color.green.opacity(0.2))
                }
            }
            Text(verbatim: "S-3 composing: \(isComposing) · submits: \(submits) · graded: \(graded)")
                .font(.caption)
            HStack {
                Button("compose か") { probe.compose("か") }
                Button("commit") { probe.commit() }
                Button("return") { probe.returnKey() }
            }
        }
        .padding(.horizontal)
    }
}
#endif
