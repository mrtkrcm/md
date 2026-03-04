//
//  ToolbarVisibilityController.swift
//  mdviewer
//
//  Manages toolbar auto-hide behavior based on scroll position.
//

internal import Foundation
internal import SwiftUI

/// Tracks scroll direction and position to control toolbar visibility.
@MainActor
final class ToolbarVisibilityController: ObservableObject {
    /// Current visibility state of the toolbar.
    @Published private(set) var isVisible: Bool = true

    /// Scroll offset after which toolbar hides (in points).
    let hideThreshold: CGFloat

    /// Distance scrolled up before showing toolbar again.
    let showThreshold: CGFloat

    /// Minimum delay between show events (debounce for show path only).
    let debounceInterval: TimeInterval

    /// Minimum time between scroll updates to throttle frequent calls.
    let scrollThrottleInterval: TimeInterval

    /// Called synchronously when visibility changes — bypasses the SwiftUI render cycle.
    var onVisibilityChange: ((Bool) -> Void)?

    // Hysteresis: toolbar auto-shows only when within this distance of the top.
    // Kept lower than hideThreshold so there is a dead zone that prevents flicker
    // when the user bounces or micro-scrolls near the hide boundary.
    private let atTopThreshold: CGFloat = 8

    private var lastScrollOffset: CGFloat = 0
    private var accumulatedScrollUp: CGFloat = 0
    private var lastVisibilityChange: Date = .distantPast
    private var lastScrollUpdate: Date = .distantPast

    init(
        hideThreshold: CGFloat = 20,
        showThreshold: CGFloat = 30,
        debounceInterval: TimeInterval = 0.05,
        scrollThrottleInterval: TimeInterval = 0.0 // No throttling, rely on coalescing
    ) {
        self.hideThreshold = hideThreshold
        self.showThreshold = showThreshold
        self.debounceInterval = debounceInterval
        self.scrollThrottleInterval = scrollThrottleInterval
    }

    /// Call this when scroll position changes.
    /// Throttled to prevent excessive updates during smooth scrolling.
    /// - Parameters:
    ///   - offset: Current scroll offset (0 = top)
    ///   - contentHeight: Total content height
    ///   - visibleHeight: Visible viewport height
    func updateScroll(offset: CGFloat, contentHeight: CGFloat, visibleHeight: CGFloat) {
        let now = Date()
        guard now.timeIntervalSince(lastScrollUpdate) >= scrollThrottleInterval else { return }
        lastScrollUpdate = now

        let delta = offset - lastScrollOffset
        lastScrollOffset = offset

        // Show at top immediately (tight zone for hysteresis — smaller than hideThreshold
        // so there is a dead zone between atTopThreshold and hideThreshold that prevents
        // the toolbar from toggling on micro-scrolls or rubber-band bounces).
        if offset <= atTopThreshold, !isVisible {
            setVisible(true)
            accumulatedScrollUp = 0
            return
        }

        if delta > 0 {
            // Scrolling down — hide immediately, no debounce
            accumulatedScrollUp = 0
            if offset > hideThreshold, isVisible {
                setVisible(false)
            }
        } else if delta < 0 {
            // Scrolling up — accumulate distance, debounce to prevent flicker on reversals
            accumulatedScrollUp += abs(delta)
            let now = Date()
            guard now.timeIntervalSince(lastVisibilityChange) >= debounceInterval else { return }
            if accumulatedScrollUp >= showThreshold, !isVisible {
                setVisible(true)
                accumulatedScrollUp = 0
            }
        }
    }

    /// Explicitly show toolbar (e.g., when mouse enters toolbar area).
    /// Includes a small delay to prevent flickering when mouse moves across boundaries.
    func show() {
        // Debounce show calls to prevent rapid toggling
        let now = Date()
        guard now.timeIntervalSince(lastVisibilityChange) >= debounceInterval else { return }

        if !isVisible {
            setVisible(true)
            accumulatedScrollUp = 0
        }
    }

    /// Reset state (e.g., when changing documents).
    func reset() {
        lastScrollOffset = 0
        accumulatedScrollUp = 0
        setVisible(true)
    }

    private func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        lastVisibilityChange = Date()
        onVisibilityChange?(visible)
    }
}

// MARK: - Environment Key

private struct ToolbarVisibilityControllerKey: EnvironmentKey {
    static let defaultValue: ToolbarVisibilityController? = nil
}

extension EnvironmentValues {
    var toolbarVisibilityController: ToolbarVisibilityController? {
        get { self[ToolbarVisibilityControllerKey.self] }
        set { self[ToolbarVisibilityControllerKey.self] = newValue }
    }
}
