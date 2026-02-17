import SwiftUI
import MarkdownUI

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
