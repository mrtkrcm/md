import SwiftUI
import MarkdownUI
import Splash

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @AppStorage("theme") private var selectedTheme: AppTheme = .basic
    @Environment(\.colorScheme) private var colorScheme

    enum AppTheme: String, CaseIterable, Identifiable {
        case basic = "Basic"
        case gitHub = "GitHub"
        case docC = "DocC"

        var id: String { rawValue }

        var theme: MarkdownUI.Theme {
            switch self {
            case .basic: return .basic
            case .gitHub: return .gitHub
            case .docC: return .docC
            }
        }
    }

    private var splashTheme: Splash.Theme {
        switch colorScheme {
        case .dark:
            return .midnight(withFont: .init(size: 14))
        default:
            return .sundellsColors(withFont: .init(size: 14))
        }
    }

    var body: some View {
        ScrollView {
            Markdown(document.text)
                .markdownTheme(selectedTheme.theme)
                .markdownCodeSyntaxHighlighter(SplashCodeSyntaxHighlighter(theme: splashTheme))
                .padding()
        }
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
