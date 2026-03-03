//
//  LiquidBackground.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Liquid Design Components

/// Subtle animated background that responds to system appearance.
/// This is a decorative element and is hidden from VoiceOver.
struct LiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if #available(macOS 15.0, *) {
                ModernLiquidBackground()
            } else {
                LegacyLiquidBackground()
            }
        }
        // Hide decorative background from VoiceOver
        .accessibilityHidden(true)
    }
}

// MARK: - ModernLiquidBackground

@available(macOS 15.0, *)
private struct ModernLiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
                .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
                .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1),
            ],
            colors: colors
        )
        .opacity(0.15)
        .blur(radius: 40)
        // Use reduced motion aware animation
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 2.0),
            value: colorScheme
        )
        // Decorative element - ensure it's hidden from accessibility
        .accessibilityHidden(true)
    }

    private var colors: [Color] {
        switch colorScheme {
        case .dark:
            return [
                .black, .black, .black,
                Color.purple.opacity(0.2), Color.blue.opacity(0.1), Color.black,
                Color.indigo.opacity(0.15), .black, Color.purple.opacity(0.1),
            ]

        default:
            return [
                .white, .white, .white,
                Color.blue.opacity(0.08), Color.purple.opacity(0.05), .white,
                Color.cyan.opacity(0.06), .white, Color.blue.opacity(0.04),
            ]
        }
    }
}

// MARK: - LegacyLiquidBackground

/// Fallback for macOS 14 using RadialGradient.
/// Respects reduced motion preferences.
private struct LegacyLiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                Color(nsColor: .windowBackgroundColor)

                // Animated orbs - only animate if reduced motion is off
                if !reduceMotion {
                    animatedOrbs(in: geometry)
                } else {
                    // Static orbs for reduced motion
                    staticOrbs(in: geometry)
                }
            }
        }
        // Decorative element - ensure it's hidden from accessibility
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func animatedOrbs(in geometry: GeometryProxy) -> some View {
        ForEach(0 ..< 3) { i in
            RadialGradient(
                colors: [
                    orbColor(for: i).opacity(0.15),
                    orbColor(for: i).opacity(0),
                ],
                center: .center,
                startRadius: 0,
                endRadius: geometry.size.width * 0.6
            )
            .offset(
                x: offsetX(for: i, width: geometry.size.width),
                y: offsetY(for: i, height: geometry.size.height)
            )
            .blur(radius: 60)
            .animation(
                .easeInOut(duration: 8 + Double(i) * 2)
                    .repeatForever(autoreverses: true),
                value: phase
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    @ViewBuilder
    private func staticOrbs(in geometry: GeometryProxy) -> some View {
        // Static version without animation for reduced motion
        ForEach(0 ..< 3) { i in
            RadialGradient(
                colors: [
                    orbColor(for: i).opacity(0.1),
                    orbColor(for: i).opacity(0),
                ],
                center: .center,
                startRadius: 0,
                endRadius: geometry.size.width * 0.6
            )
            .offset(
                x: offsetX(for: i, width: geometry.size.width),
                y: offsetY(for: i, height: geometry.size.height)
            )
            .blur(radius: 60)
        }
    }

    private func orbColor(for index: Int) -> Color {
        switch (colorScheme, index) {
        case (.dark, 0): return .purple
        case (.dark, 1): return .blue
        case (.dark, _): return .indigo

        default:
            return [.blue, .cyan, .purple][index]
        }
    }

    private func offsetX(for index: Int, width: CGFloat) -> CGFloat {
        let offsets: [CGFloat] = [-width * 0.2, width * 0.3, -width * 0.1]
        return offsets[index]
    }

    private func offsetY(for index: Int, height: CGFloat) -> CGFloat {
        let offsets: [CGFloat] = [-height * 0.1, height * 0.2, height * 0.3]
        return offsets[index]
    }
}

// MARK: - Previews

#Preview("Liquid Background - Light") {
    LiquidBackground()
        .preferredColorScheme(.light)
}

#Preview("Liquid Background - Dark") {
    LiquidBackground()
        .preferredColorScheme(.dark)
}

#Preview("Liquid Background - Reduced Motion") {
    // Note: accessibilityReduceMotion is read-only and cannot be set via environment()
    // This preview demonstrates the static orb appearance used when reduced motion is enabled
    LiquidBackground()
}
