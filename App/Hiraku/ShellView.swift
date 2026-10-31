import SwiftUI

struct ShellView: View {
    @State private var pingResult = "—"

    var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: "hiraku")
                .font(.largeTitle)
            Text("Khung M0 — chưa có tính năng")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #if DEBUG
            PingCheckView(result: $pingResult)
            FontCheckView()
            #endif
        }
        .padding()
    }
}
