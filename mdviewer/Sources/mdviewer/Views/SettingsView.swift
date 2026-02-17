import SwiftUI

struct SettingsView: View {
    @AppStorage("theme") private var selectedTheme: AppTheme = .basic

    var body: some View {
        Form {
            Picker("Theme", selection: $selectedTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.inline)
        }
        .frame(width: 300, height: 100)
        .padding()
    }
}
