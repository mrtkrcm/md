//
//  AppPreferences.swift
//  mdviewer
//

internal import SwiftUI

/// Centralized application preferences using @Observable with manual observation support.
@MainActor
@Observable
final class AppPreferences {
    // MARK: - Shared Instance

    static let shared = AppPreferences()

    // MARK: - Published Properties (for observation)

    var theme: AppTheme {
        get {
            access(keyPath: \.theme)
            return AppTheme(rawValue: UserDefaults.standard.string(forKey: Keys.theme) ?? "") ?? .github
        }
        set {
            withMutation(keyPath: \.theme) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.theme)
            }
        }
    }

    var syntaxPalette: SyntaxPalette {
        get {
            access(keyPath: \.syntaxPalette)
            return SyntaxPalette(rawValue: UserDefaults.standard.string(forKey: Keys.syntaxPalette) ?? "") ?? .midnight
        }
        set {
            withMutation(keyPath: \.syntaxPalette) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.syntaxPalette)
            }
        }
    }

    var readerFontSize: ReaderFontSize {
        get {
            access(keyPath: \.readerFontSize)
            return ReaderFontSize(rawValue: UserDefaults.standard.integer(forKey: Keys.readerFontSize)) ?? .standard
        }
        set {
            withMutation(keyPath: \.readerFontSize) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerFontSize)
            }
        }
    }

    var codeFontSize: CodeFontSize {
        get {
            access(keyPath: \.codeFontSize)
            return CodeFontSize(rawValue: UserDefaults.standard.integer(forKey: Keys.codeFontSize)) ?? .medium
        }
        set {
            withMutation(keyPath: \.codeFontSize) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.codeFontSize)
            }
        }
    }

    var appearanceMode: AppearanceMode {
        get {
            access(keyPath: \.appearanceMode)
            return AppearanceMode(rawValue: UserDefaults.standard.string(forKey: Keys.appearanceMode) ?? "") ?? .auto
        }
        set {
            withMutation(keyPath: \.appearanceMode) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.appearanceMode)
            }
        }
    }

    var readerFontFamily: ReaderFontFamily {
        get {
            access(keyPath: \.readerFontFamily)
            return ReaderFontFamily(rawValue: UserDefaults.standard.string(forKey: Keys.readerFontFamily) ?? "") ??
                .newYork
        }
        set {
            withMutation(keyPath: \.readerFontFamily) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerFontFamily)
            }
        }
    }

    var readerMode: ReaderMode {
        get {
            access(keyPath: \.readerMode)
            return ReaderMode(rawValue: UserDefaults.standard.string(forKey: Keys.readerMode) ?? "") ?? .rendered
        }
        set {
            withMutation(keyPath: \.readerMode) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerMode)
            }
        }
    }

    var readerTextSpacing: ReaderTextSpacing {
        get {
            access(keyPath: \.readerTextSpacing)
            return ReaderTextSpacing(rawValue: UserDefaults.standard.string(forKey: Keys.readerTextSpacing) ?? "") ??
                .balanced
        }
        set {
            withMutation(keyPath: \.readerTextSpacing) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerTextSpacing)
            }
        }
    }

    var readerColumnWidth: ReaderColumnWidth {
        get {
            access(keyPath: \.readerColumnWidth)
            return ReaderColumnWidth(rawValue: UserDefaults.standard.string(forKey: Keys.readerColumnWidth) ?? "") ??
                .balanced
        }
        set {
            withMutation(keyPath: \.readerColumnWidth) {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerColumnWidth)
            }
        }
    }

    var showLineNumbers: Bool {
        get {
            access(keyPath: \.showLineNumbers)
            return UserDefaults.standard.bool(forKey: Keys.showLineNumbers)
        }
        set {
            withMutation(keyPath: \.showLineNumbers) {
                UserDefaults.standard.set(newValue, forKey: Keys.showLineNumbers)
            }
        }
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let theme = "theme"
        static let syntaxPalette = "syntaxPalette"
        static let readerFontSize = "readerFontSize"
        static let codeFontSize = "codeFontSize"
        static let appearanceMode = "appearanceMode"
        static let readerFontFamily = "readerFontFamily"
        static let readerMode = "readerMode"
        static let readerTextSpacing = "readerTextSpacing"
        static let readerColumnWidth = "readerColumnWidth"
        static let showLineNumbers = "showLineNumbers"
    }

    // MARK: - Computed Properties

    var effectiveColorScheme: ColorScheme? {
        appearanceMode.preferredColorScheme
    }

    var canIncreaseFontSize: Bool {
        let sizes = ReaderFontSize.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let currentIndex = sizes.firstIndex(of: readerFontSize) else { return false }
        return currentIndex < sizes.count - 1
    }

    var canDecreaseFontSize: Bool {
        let sizes = ReaderFontSize.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let currentIndex = sizes.firstIndex(of: readerFontSize) else { return false }
        return currentIndex > 0
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Font Size Actions

    func increaseFontSize() {
        let sizes = ReaderFontSize.allCases.sorted { $0.rawValue < $1.rawValue }
        guard
            let currentIndex = sizes.firstIndex(of: readerFontSize),
            currentIndex < sizes.count - 1 else { return }
        readerFontSize = sizes[currentIndex + 1]
    }

    func decreaseFontSize() {
        let sizes = ReaderFontSize.allCases.sorted { $0.rawValue < $1.rawValue }
        guard
            let currentIndex = sizes.firstIndex(of: readerFontSize),
            currentIndex > 0 else { return }
        readerFontSize = sizes[currentIndex - 1]
    }

    func resetFontSize() {
        readerFontSize = .standard
    }

    // MARK: - Reader Mode Actions

    func setRenderedMode() {
        readerMode = .rendered
    }

    func setRawMode() {
        readerMode = .raw
    }
}

// MARK: - Environment Key

private struct PreferencesKey: EnvironmentKey {
    /// Access the shared instance in a way compatible with EnvironmentKey
    /// The MainActor isolation is handled internally by AppPreferences
    static var defaultValue: AppPreferences {
        MainActor.assumeIsolated { AppPreferences.shared }
    }
}

extension EnvironmentValues {
    var preferences: AppPreferences {
        get { self[PreferencesKey.self] }
        set { self[PreferencesKey.self] = newValue }
    }
}
