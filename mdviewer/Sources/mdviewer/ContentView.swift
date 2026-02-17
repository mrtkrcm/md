import SwiftUI
import MarkdownUI

struct ContentView: View {
    @State private var selectedTheme: AppTheme = .basic

    enum AppTheme: String, CaseIterable, Identifiable {
        case basic = "Basic"
        case gitHub = "GitHub"
        case docC = "DocC"

        var id: String { rawValue }

        var theme: Theme {
            switch self {
            case .basic: return .basic
            case .gitHub: return .gitHub
            case .docC: return .docC
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                Markdown(SampleData.content)
                    .markdownTheme(selectedTheme.theme)
                    .padding()
            }
            .navigationTitle("Markdown Viewer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Theme", selection: $selectedTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush")
                    }
                }
            }
        }
    }
}
