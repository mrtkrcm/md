import SwiftUI
import MarkdownUI
import Splash
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @AppStorage("theme") private var selectedTheme: AppTheme = .basic
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            Markdown(document.text)
                .markdownTheme(selectedTheme.theme)
                .markdownCodeSyntaxHighlighter(SplashCodeSyntaxHighlighter(theme: splashTheme))
                .markdownBlockStyle(\.codeBlock) { configuration in
                    VStack(spacing: 0) {
                        HStack {
                            Text(configuration.language?.capitalized ?? "Text")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            #if os(macOS)
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(configuration.content, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Copy code")
                            #endif
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.05))

                        Divider()

                        configuration.label
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.02))
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.bottom)
                }
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

    private var splashTheme: Splash.Theme {
        switch colorScheme {
        case .dark:
            return .midnight(withFont: .init(size: 14))
        default:
            return .sundellsColors(withFont: .init(size: 14))
        }
    }
}
