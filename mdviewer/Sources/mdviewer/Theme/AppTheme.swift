//
//  AppTheme.swift
//  mdviewer
//

internal import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case github = "GitHub"
    case docC = "DocC"

    var id: String { rawValue }
}

extension AppTheme: StoredPreference {
    static func from(rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .basic
    }
}
