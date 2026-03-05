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

    /// Defer complex rendering slightly until after the first frame
    @State private var isReady = false

    var body: some View {
        ZStack {
            // Instant solid color for the first frame
            Color(nsColor: .windowBackgroundColor)

            if isReady {
                meshGradientView
            }
        }
        .onAppear {
            // Smallest possible delay to let the text content render first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isReady = true
            }
        }
        // Hide decorative background from VoiceOver
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var meshGradientView: some View {
        if #available(macOS 15.0, *) {
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
            .transition(.opacity.animation(.easeIn(duration: 0.4)))
        } else {
            // Fallback for macOS 14 - use radial gradient
            fallbackGradient
        }
    }

    private var fallbackGradient: some View {
        RadialGradient(
            gradient: Gradient(colors: fallbackColors),
            center: .center,
            startRadius: 0,
            endRadius: 400
        )
        .opacity(0.2)
        .blur(radius: 50)
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 2.0),
            value: colorScheme
        )
    }

    private var fallbackColors: [Color] {
        switch colorScheme {
        case .dark:
            return [.purple.opacity(0.3), .blue.opacity(0.2), .black]
        default:
            return [.blue.opacity(0.1), .purple.opacity(0.08), .white]
        }
    }

    private var colors: [Color] {
        switch colorScheme {
        case .dark:
            return [
                .black, .black, .black,
                Color.purple.opacity(0.35), Color.blue.opacity(0.2), Color.black,
                Color.indigo.opacity(0.25), .black, Color.purple.opacity(0.15),
            ]

        default:
            return [
                .white, .white, .white,
                Color.blue.opacity(0.12), Color.purple.opacity(0.08), .white,
                Color.cyan.opacity(0.1), .white, Color.blue.opacity(0.06),
            ]
        }
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
    LiquidBackground()
}
