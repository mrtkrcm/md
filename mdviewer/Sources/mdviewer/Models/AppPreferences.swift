//
//  AppPreferences.swift
//  mdviewer
//

internal import SwiftUI

/// Centralized application preferences using @Observable with in-memory backing storage.
///
/// Values are read from UserDefaults once at initialization and cached in-memory backing
/// properties. Writes update both the backing store and UserDefaults atomically inside
/// `withMutation`, so SwiftUI observation is always notified correctly without triggering
/// redundant UserDefaults I/O on every property access.
@MainActor
@Observable
final class AppPreferences {
    // MARK: - Shared Instance

    static let shared = AppPreferences()

    // MARK: - Backing Storage

    @ObservationIgnored private var _theme: AppTheme
    @ObservationIgnored private var _syntaxPalette: SyntaxPalette
    @ObservationIgnored private var _readerFontSize: ReaderFontSize
    @ObservationIgnored private var _codeFontSize: CodeFontSize
    @ObservationIgnored private var _appearanceMode: AppearanceMode
    @ObservationIgnored private var _readerFontFamily: ReaderFontFamily
    @ObservationIgnored private var _readerMode: ReaderMode
    @ObservationIgnored private var _readerTextSpacing: ReaderTextSpacing
    @ObservationIgnored private var _readerColumnWidth: ReaderColumnWidth
    @ObservationIgnored private var _readerContentPadding: ReaderContentPadding
    @ObservationIgnored private var _showLineNumbers: Bool
    @ObservationIgnored private var _typographyPreferences: TypographyPreferences
    @ObservationIgnored private var _largeFileThreshold: LargeFileThreshold

    // MARK: - Observed Properties

    var theme: AppTheme {
        get {
            access(keyPath: \.theme)
            return _theme
        }
        set {
            withMutation(keyPath: \.theme) {
                _theme = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.theme)
            }
        }
    }

    var syntaxPalette: SyntaxPalette {
        get {
            access(keyPath: \.syntaxPalette)
            return _syntaxPalette
        }
        set {
            withMutation(keyPath: \.syntaxPalette) {
                _syntaxPalette = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.syntaxPalette)
            }
        }
    }

    var readerFontSize: ReaderFontSize {
        get {
            access(keyPath: \.readerFontSize)
            return _readerFontSize
        }
        set {
            withMutation(keyPath: \.readerFontSize) {
                _readerFontSize = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerFontSize)
            }
        }
    }

    var codeFontSize: CodeFontSize {
        get {
            access(keyPath: \.codeFontSize)
            return _codeFontSize
        }
        set {
            withMutation(keyPath: \.codeFontSize) {
                _codeFontSize = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.codeFontSize)
            }
        }
    }

    var appearanceMode: AppearanceMode {
        get {
            access(keyPath: \.appearanceMode)
            return _appearanceMode
        }
        set {
            withMutation(keyPath: \.appearanceMode) {
                _appearanceMode = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.appearanceMode)
            }
        }
    }

    var readerFontFamily: ReaderFontFamily {
        get {
            access(keyPath: \.readerFontFamily)
            return _readerFontFamily
        }
        set {
            withMutation(keyPath: \.readerFontFamily) {
                _readerFontFamily = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerFontFamily)
            }
        }
    }

    var readerMode: ReaderMode {
        get {
            access(keyPath: \.readerMode)
            return _readerMode
        }
        set {
            withMutation(keyPath: \.readerMode) {
                _readerMode = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerMode)
            }
        }
    }

    var readerTextSpacing: ReaderTextSpacing {
        get {
            access(keyPath: \.readerTextSpacing)
            return _readerTextSpacing
        }
        set {
            withMutation(keyPath: \.readerTextSpacing) {
                _readerTextSpacing = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerTextSpacing)
            }
        }
    }

    var readerColumnWidth: ReaderColumnWidth {
        get {
            access(keyPath: \.readerColumnWidth)
            return _readerColumnWidth
        }
        set {
            withMutation(keyPath: \.readerColumnWidth) {
                _readerColumnWidth = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerColumnWidth)
            }
        }
    }

    var readerContentPadding: ReaderContentPadding {
        get {
            access(keyPath: \.readerContentPadding)
            return _readerContentPadding
        }
        set {
            withMutation(keyPath: \.readerContentPadding) {
                _readerContentPadding = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.readerContentPadding)
            }
        }
    }

    var showLineNumbers: Bool {
        get {
            access(keyPath: \.showLineNumbers)
            return _showLineNumbers
        }
        set {
            withMutation(keyPath: \.showLineNumbers) {
                _showLineNumbers = newValue
                UserDefaults.standard.set(newValue, forKey: Keys.showLineNumbers)
            }
        }
    }

    var typographyPreferences: TypographyPreferences {
        get {
            access(keyPath: \.typographyPreferences)
            return _typographyPreferences
        }
        set {
            withMutation(keyPath: \.typographyPreferences) {
                _typographyPreferences = newValue
                if let data = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(data, forKey: Keys.typographyPreferences)
                }
            }
        }
    }

    var largeFileThreshold: LargeFileThreshold {
        get {
            access(keyPath: \.largeFileThreshold)
            return _largeFileThreshold
        }
        set {
            withMutation(keyPath: \.largeFileThreshold) {
                _largeFileThreshold = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.largeFileThreshold)
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
        static let readerContentPadding = "readerContentPadding"
        static let showLineNumbers = "showLineNumbers"
        static let typographyPreferences = "typographyPreferences"
        static let largeFileThreshold = "largeFileThreshold"
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

    private init() {
        let ud = UserDefaults.standard
        _theme = AppTheme(rawValue: ud.string(forKey: Keys.theme) ?? "") ?? .github
        _syntaxPalette = SyntaxPalette(rawValue: ud.string(forKey: Keys.syntaxPalette) ?? "") ?? .midnight
        _readerFontSize = ReaderFontSize(rawValue: ud.integer(forKey: Keys.readerFontSize)) ?? .standard
        _codeFontSize = CodeFontSize(rawValue: ud.integer(forKey: Keys.codeFontSize)) ?? .medium
        _appearanceMode = AppearanceMode(rawValue: ud.string(forKey: Keys.appearanceMode) ?? "") ?? .auto
        _readerFontFamily = ReaderFontFamily(rawValue: ud.string(forKey: Keys.readerFontFamily) ?? "") ?? .newYork
        _readerMode = ReaderMode(rawValue: ud.string(forKey: Keys.readerMode) ?? "") ?? .rendered
        _readerTextSpacing = ReaderTextSpacing(rawValue: ud.string(forKey: Keys.readerTextSpacing) ?? "") ?? .balanced
        _readerColumnWidth = ReaderColumnWidth(rawValue: ud.string(forKey: Keys.readerColumnWidth) ?? "") ?? .balanced
        _readerContentPadding = ReaderContentPadding(rawValue: ud.string(forKey: Keys.readerContentPadding) ?? "") ??
            .normal
        _showLineNumbers = ud.bool(forKey: Keys.showLineNumbers)
        if
            let data = ud.data(forKey: Keys.typographyPreferences),
            let prefs = try? JSONDecoder().decode(TypographyPreferences.self, from: data)
        {
            _typographyPreferences = prefs
        } else {
            _typographyPreferences = TypographyPreferences()
        }
        _largeFileThreshold = LargeFileThreshold.from(rawValue: ud.integer(forKey: Keys.largeFileThreshold))
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
