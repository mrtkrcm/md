import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case github = "GitHub"
    case docC = "DocC"

    var id: String { rawValue }
}
