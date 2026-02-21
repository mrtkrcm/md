//
//  ReaderFontFamily.swift
//  mdviewer
//

internal import SwiftUI
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Reader Font Family

enum ReaderFontFamily: String, CaseIterable, Identifiable, Sendable {
    case mapleMonoNF = "Maple Mono NF"
    case sfPro = "SF Pro Text"
    case newYork = "New York"
    case georgia = "Georgia"

    var id: String { rawValue }

    static func from(rawValue: String) -> ReaderFontFamily {
        ReaderFontFamily(rawValue: rawValue) ?? .newYork
    }

    func font(size: CGFloat) -> SwiftUI.Font {
        switch self {
        case .mapleMonoNF:
            return .custom("Maple Mono NF", size: size)
        case .sfPro:
            return .system(size: size, weight: .regular, design: .default)
        case .newYork:
            return .custom("New York", size: size)
        case .georgia:
            return .custom("Georgia", size: size)
        }
    }

    #if os(macOS)
        /// Returns an NSFont for this family at the given size.
        /// Pass `monospaced: true` to get the code font regardless of the chosen family.
        /// Pass `weight` to control font weight (light, regular, medium, semibold, bold, heavy).
        /// Pass `traits` to apply bold/italic/both on top of the base descriptor.
        func nsFont(
            size: CGFloat,
            monospaced: Bool = false,
            weight: NSFont.Weight = .regular,
            traits: NSFontDescriptor.SymbolicTraits = []
        ) -> NSFont {
            let base: NSFont = resolveBaseFont(size: size, monospaced: monospaced, weight: weight)
            guard !traits.isEmpty else { return base }
            let desc = base.fontDescriptor.withSymbolicTraits(traits)
            return NSFont(descriptor: desc, size: base.pointSize) ?? base
        }

        private func resolveBaseFont(size: CGFloat, monospaced: Bool, weight: NSFont.Weight) -> NSFont {
            // Monospaced: prefer Maple Mono NF when available, fall back to system mono.
            if monospaced {
                if weight == .regular {
                    if let f = NSFont(name: "MapleMono-NF-Regular", size: size) { return f }
                    if let f = NSFont(name: "Maple Mono NF", size: size) { return f }
                }
                let desc = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.monospaced)
                return desc.flatMap { NSFont(descriptor: $0, size: size) }
                    ?? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
            }

            switch self {
            case .mapleMonoNF:
                // For monospace family, use system mono with weight
                let desc = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.monospaced)
                return desc.flatMap { NSFont(descriptor: $0, size: size) }
                    ?? NSFont.monospacedSystemFont(ofSize: size, weight: weight)

            case .sfPro:
                // Use system font with specified weight
                return NSFont.systemFont(ofSize: size, weight: weight)

            case .newYork:
                // "New York" is not accessible via NSFont(name:) — use descriptor design.
                let baseFont = NSFont.systemFont(ofSize: size, weight: weight)
                let desc = baseFont.fontDescriptor.withDesign(.serif)
                if let f = desc.flatMap({ NSFont(descriptor: $0, size: size) }) { return f }
                if let f = NSFont(name: "Georgia", size: size) { return f }
                return baseFont

            case .georgia:
                if let f = NSFont(name: "Georgia", size: size) {
                    // Georgia loaded by name won't have weight, apply it via descriptor
                    if weight != .regular {
                        let desc = f.fontDescriptor.withSymbolicTraits(.bold)
                        if let weighted = NSFont(descriptor: desc, size: size) { return weighted }
                    }
                    return f
                }
                let baseFont = NSFont.systemFont(ofSize: size, weight: weight)
                let desc = baseFont.fontDescriptor.withDesign(.serif)
                return desc.flatMap { NSFont(descriptor: $0, size: size) }
                    ?? baseFont
            }
        }
    #endif
}

// MARK: - StoredPreference Conformance

extension ReaderFontFamily: StoredPreference {}
