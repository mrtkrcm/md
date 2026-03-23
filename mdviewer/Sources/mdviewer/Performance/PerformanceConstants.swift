//
//  PerformanceConstants.swift
//  mdviewer
//
//  120fps performance optimization constants and utilities.
//

internal import Foundation
#if os(macOS)
    internal import AppKit
    internal import QuartzCore
#endif

// MARK: - 120fps Constants

/// Performance constants tuned for 120fps (120Hz ProMotion displays).
enum PerformanceConstants {
    /// Target frame duration for 120fps (8.33ms).
    static let targetFrameDuration: TimeInterval = 1.0 / 120.0

    /// Target frame duration in nanoseconds.
    static let targetFrameDurationNanos: UInt64 = .init(targetFrameDuration * 1_000_000_000)

    /// Maximum frame time before dropping frames (10ms = 100fps minimum).
    static let maxFrameTime: TimeInterval = 0.010

    /// Coalescing delay for scroll events (1ms for 120fps precision).
    static let scrollCoalescingDelay: TimeInterval = 0.001

    /// Minimum scroll delta to report (sub-pixel precision for smooth 120fps).
    static let minScrollDelta: CGFloat = 0.5

    /// Delay before considering a scroll gesture settled.
    static let scrollSettleDelay: TimeInterval = 0.05

    /// Delay after launch before background prewarming starts.
    static let startupPrewarmDelay: TimeInterval = 0.15

    /// Threshold for considering scroll velocity "fast" (points/second).
    static let fastScrollVelocity: CGFloat = 2000

    /// Maximum time for layout operations during scroll (2ms).
    static let maxLayoutTime: TimeInterval = 0.002
}

// MARK: - Display Link Support

#if os(macOS)
    /// A display link callback handler for 120fps synchronized updates.
    /// Note: This is a simplified implementation. Currently using Task-based coalescing
    /// which provides sufficient performance for 120fps scrolling.
    @MainActor
    final class DisplayLinkHandler: Sendable {
        private var callback: (@Sendable () -> Void)?
        private var timer: Timer?

        var isRunning: Bool { timer != nil }

        /// Starts display-synchronized callbacks (simulated at 120Hz).
        func start(callback: @escaping @Sendable () -> Void) {
            self.callback = callback

            // Use a high-frequency timer to simulate display link
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { _ in
                callback()
            }
        }

        /// Stops the display link simulation.
        func stop() {
            timer?.invalidate()
            timer = nil
            callback = nil
        }
    }
#endif

// MARK: - Performance Monitoring

/// Simple performance monitor for tracking frame times.
@MainActor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private var frameStartTime: TimeInterval = 0
    private var frameTimes: [TimeInterval] = []
    private let maxFrameHistory = 120 // 1 second at 120fps

    private init() {}

    /// Marks the start of a frame.
    func beginFrame() {
        frameStartTime = CACurrentMediaTime()
    }

    /// Marks the end of a frame and records the duration.
    func endFrame() {
        let duration = CACurrentMediaTime() - frameStartTime
        frameTimes.append(duration)

        if frameTimes.count > maxFrameHistory {
            frameTimes.removeFirst()
        }
    }

    /// Returns the average frame time over the last second.
    var averageFrameTime: TimeInterval {
        guard !frameTimes.isEmpty else { return 0 }
        return frameTimes.reduce(0, +) / Double(frameTimes.count)
    }

    /// Returns the current FPS based on average frame time.
    var currentFPS: Double {
        let avg = averageFrameTime
        guard avg > 0 else { return 0 }
        return 1.0 / avg
    }

    /// Returns the 99th percentile frame time (worst case).
    var worstFrameTime: TimeInterval {
        guard !frameTimes.isEmpty else { return 0 }
        return frameTimes.sorted().dropLast(max(0, frameTimes.count / 100)).last ?? 0
    }

    /// Returns true if frame times indicate dropped frames.
    var isDroppingFrames: Bool {
        worstFrameTime > PerformanceConstants.maxFrameTime
    }
}

// MARK: - Layer Optimization Helpers

#if os(macOS)
    extension NSView {
        /// Optimizes the view for smooth 120fps animations.
        func optimizeFor120fps() {
            wantsLayer = true
            layer?.drawsAsynchronously = true

            // Disable actions during scroll for performance
            layer?.actions = [
                "onOrderIn": NSNull(),
                "onOrderOut": NSNull(),
                "sublayers": NSNull(),
                "contents": NSNull(),
                "bounds": NSNull(),
            ]
        }

        /// Restores normal layer actions for animations.
        func restoreLayerActions() {
            layer?.actions = nil
        }
    }
#endif

// MARK: - Scroll Performance

/// Configuration for scroll-optimized operations.
struct ScrollPerformanceConfig {
    /// Whether to skip expensive operations during fast scrolling.
    var skipWorkDuringFastScroll: Bool = true

    /// Velocity threshold for considering scroll "fast".
    var fastScrollThreshold: CGFloat = PerformanceConstants.fastScrollVelocity

    /// Whether to defer layout until scroll settles.
    var deferLayoutDuringScroll: Bool = true

    /// Time to wait after scroll ends before resuming expensive work.
    var scrollSettleDelay: TimeInterval = 0.05

    /// Default configuration for 120fps.
    static let `default` = ScrollPerformanceConfig()
}
