import SwiftUI

struct ShellView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: "hiraku")
                .font(.largeTitle)
            Text("Khung M0 — chưa có tính năng")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
