#if DEBUG
import SwiftUI

struct SampleWord: Identifiable, Hashable {
    let id: Int
    let term: String
    let reading: String
    let meaning: String
}

// One controller feeds both the compact List and the regular Table.
@Observable
@MainActor
final class SampleWordsController {
    let words = (1...40).map {
        SampleWord(id: $0, term: "食べる\($0)", reading: "たべる", meaning: "ăn \($0)")
    }
    var selection: SampleWord.ID?
    var dueCount = 12
}

// Debug-only S-4 check: system chrome with List on iPhone, Table + sidebar + 230pt inspector elsewhere.
// Spike shell keeps plain strings; String Catalog and COPY come with product UI.
struct AdaptiveCheckView: View {
    @State private var controller = SampleWordsController()
    @State private var showInspector = true
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .compact {
            compact
        } else {
            regular
        }
    }

    private var compact: some View {
        TabView {
            Tab("Trang chủ", systemImage: "house") { Text(verbatim: "Home") }
            Tab("Deck", systemImage: "books.vertical") {
                NavigationStack {
                    List(controller.words) { word in
                        Text(verbatim: "\(word.term) · \(word.reading)")
                            .font(.custom(NotoFont.regular, size: 20))
                    }
                    .navigationTitle(Text(verbatim: "Động từ cơ bản"))
                }
            }
            Tab("Cài đặt", systemImage: "gearshape") { Text(verbatim: "Settings") }
        }
        #if os(iOS)
        .tabViewBottomAccessory {
            HStack {
                Text(verbatim: "Đến hạn: \(controller.dueCount) từ")
                Button(String("Ôn ngay")) {}
            }
            .padding(.horizontal)
        }
        #endif
    }

    private var regular: some View {
        NavigationSplitView {
            List {
                Text(verbatim: "Trang chủ")
                Text(verbatim: "Động từ cơ bản")
                Text(verbatim: "Cài đặt")
            }
            .navigationTitle(Text(verbatim: "hiraku"))
        } detail: {
            Table(controller.words, selection: $controller.selection) {
                TableColumn(String("Từ")) { Text(verbatim: $0.term).font(.custom(NotoFont.regular, size: 18)) }
                TableColumn(String("Cách đọc"), value: \.reading)
                TableColumn(String("Nghĩa"), value: \.meaning)
            }
            .inspector(isPresented: $showInspector) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Phiên học").font(.headline)
                    Text(verbatim: "Đến hạn: \(controller.dueCount)")
                    Text(verbatim: "Chọn: \(controller.selection.map(String.init) ?? "—")")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .inspectorColumnWidth(min: 230, ideal: 230, max: 230)
            }
            .toolbar {
                Button(String("Inspector"), systemImage: "sidebar.trailing") { showInspector.toggle() }
            }
        }
    }
}
#endif
