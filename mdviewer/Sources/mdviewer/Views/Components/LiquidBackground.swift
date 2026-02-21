internal import SwiftUI

// MARK: - Liquid Design Components

/// Subtle animated background that responds to system appearance.
struct LiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if #available(macOS 15.0, *) {
                ModernLiquidBackground()
            } else {
                LegacyLiquidBackground()
            }
        }
    }
}

// MARK: - ModernLiquidBackground

@available(macOS 15.0, *)
private struct ModernLiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { _ in
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
                    .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
                    .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1)
                ],
                colors: colors
            )
            .opacity(0.15)
            .blur(radius: 40)
        }
        .animation(.easeInOut(duration: 2.0), value: colorScheme)
    }

    private var colors: [Color] {
        switch colorScheme {
        case .dark:
            return [
                .black, .black, .black,
                Color.purple.opacity(0.2), Color.blue.opacity(0.1), Color.black,
                Color.indigo.opacity(0.15), .black, Color.purple.opacity(0.1)
            ]
        default:
            return [
                .white, .white, .white,
                Color.blue.opacity(0.08), Color.purple.opacity(0.05), .white,
                Color.cyan.opacity(0.06), .white, Color.blue.opacity(0.04)
            ]
        }
    }
}

// MARK: - LegacyLiquidBackground

/// Fallback for macOS 14 using RadialGradient.
private struct LegacyLiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                Color(nsColor: .windowBackgroundColor)

                // Animated orbs
                ForEach(0..<3) { i in
                    RadialGradient(
                        colors: [
                            orbColor(for: i).opacity(0.15),
                            orbColor(for: i).opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.6
                    )
                    .offset(x: offsetX(for: i, width: geometry.size.width),
                            y: offsetY(for: i, height: geometry.size.height))
                    .blur(radius: 60)
                    .animation(
                        .easeInOut(duration: 8 + Double(i) * 2)
                        .repeatForever(autoreverses: true),
                        value: phase
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = 1
            }
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
