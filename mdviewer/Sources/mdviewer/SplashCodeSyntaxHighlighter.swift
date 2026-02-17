import SwiftUI
import MarkdownUI
import Splash

struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<AttributedStringOutputFormat>

    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme))
    }

    func highlightCode(_ code: String, language: String?) -> Text {
        guard let language = language, language.lowercased() == "swift" else {
            return Text(code)
        }
        return Text(self.syntaxHighlighter.highlight(code))
    }
}

struct AttributedStringOutputFormat: OutputFormat {
    private let theme: Splash.Theme

    init(theme: Splash.Theme) {
        self.theme = theme
    }

    func makeBuilder() -> Builder {
        Builder(theme: theme)
    }
}

extension AttributedStringOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var accumulatedText = AttributedString()

        init(theme: Splash.Theme) {
            self.theme = theme
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = theme.tokenColors[type] ?? theme.plainTextColor
            var attributedString = AttributedString(token)
            attributedString.foregroundColor = SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
            accumulatedText.append(attributedString)
        }

        mutating func addPlainText(_ text: String) {
            var attributedString = AttributedString(text)
            let color = theme.plainTextColor
            attributedString.foregroundColor = SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
            accumulatedText.append(attributedString)
        }

        mutating func addWhitespace(_ whitespace: String) {
            var attributedString = AttributedString(whitespace)
            let color = theme.plainTextColor
            attributedString.foregroundColor = SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
            accumulatedText.append(attributedString)
        }

        func build() -> AttributedString {
            accumulatedText
        }
    }
}
