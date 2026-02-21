internal import SwiftUI

// MARK: - Stored Preference Protocol

/// Preference enum that can round-trip through `UserDefaults` via its `RawValue`.
/// Conforming types get a `Binding.stored()` extension for use with `@AppStorage`.
///
/// Conformance should be declared in the same file as the enum definition to satisfy
/// Swift 6's strict Sendable requirements.
protocol StoredPreference: RawRepresentable, CaseIterable, Identifiable, Sendable {
    static func from(rawValue: RawValue) -> Self
}

// MARK: - AppStorage Binding Helpers

extension Binding where Value == String {
    /// Lifts a raw-string `@AppStorage` binding to a typed `Binding<T>`.
    ///
    /// ```swift
    /// Picker("Theme", selection: $themeRaw.stored()) { ... }
    /// ```
    func stored<T: StoredPreference>() -> Binding<T> where T.RawValue == String {
        Binding<T>(
            get: { T.from(rawValue: wrappedValue) },
            set: { wrappedValue = $0.rawValue }
        )
    }
}

extension Binding where Value == Int {
    /// Lifts a raw-int `@AppStorage` binding to a typed `Binding<T>`.
    func stored<T: StoredPreference>() -> Binding<T> where T.RawValue == Int {
        Binding<T>(
            get: { T.from(rawValue: wrappedValue) },
            set: { wrappedValue = $0.rawValue }
        )
    }
}
