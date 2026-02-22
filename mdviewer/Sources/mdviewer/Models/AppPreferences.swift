//
//  AppPreferences.swift
//  mdviewer
//

internal import SwiftUI

/// Centralized application preferences using modern @Observable pattern.
///
/// Replaces scattered @AppStorage properties with a type-safe, observable
/// object that automatically persists to UserDefaults.
@MainActor
@Observable
final class AppPreferences {
    // MARK: - Shared Instance

    static let shared = AppPreferences()

    // MARK: - Properties

    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    var syntaxPalette: SyntaxPalette {
        didSet { UserDefaults.standard.set(syntaxPalette.rawValue, forKey: Keys.syntaxPalette) }
    }

    var readerFontSize: ReaderFontSize {
        didSet { UserDefaults.standard.set(readerFontSize.rawValue, forKey: Keys.readerFontSize) }
    }

    var codeFontSize: CodeFontSize {
        didSet { UserDefaults.standard.set(codeFontSize.rawValue, forKey: Keys.codeFontSize) }
    }

    var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }

    var readerFontFamily: ReaderFontFamily {
        didSet { UserDefaults.standard.set(readerFontFamily.rawValue, forKey: Keys.readerFontFamily) }
    }

    var readerMode: ReaderMode {
        didSet { UserDefaults.standard.set(readerMode.rawValue, forKey: Keys.readerMode) }
    }

    var readerTextSpacing: ReaderTextSpacing {
        didSet { UserDefaults.standard.set(readerTextSpacing.rawValue, forKey: Keys.readerTextSpacing) }
    }

    var readerColumnWidth: ReaderColumnWidth {
        didSet { UserDefaults.standard.set(readerColumnWidth.rawValue, forKey: Keys.readerColumnWidth) }
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
    }

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        theme = AppTheme.from(rawValue: defaults.string(forKey: Keys.theme) ?? "")
        syntaxPalette = SyntaxPalette.from(rawValue: defaults.string(forKey: Keys.syntaxPalette) ?? "")
        readerFontSize = ReaderFontSize.from(rawValue: defaults.integer(forKey: Keys.readerFontSize))
        codeFontSize = CodeFontSize.from(rawValue: defaults.integer(forKey: Keys.codeFontSize))
        appearanceMode = AppearanceMode.from(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "")
        readerFontFamily = ReaderFontFamily.from(rawValue: defaults.string(forKey: Keys.readerFontFamily) ?? "")
        readerMode = ReaderMode.from(rawValue: defaults.string(forKey: Keys.readerMode) ?? "")
        readerTextSpacing = ReaderTextSpacing.from(rawValue: defaults.string(forKey: Keys.readerTextSpacing) ?? "")
        readerColumnWidth = ReaderColumnWidth.from(rawValue: defaults.string(forKey: Keys.readerColumnWidth) ?? "")
    }

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
