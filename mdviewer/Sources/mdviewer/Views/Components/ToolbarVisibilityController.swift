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

    /// Scroll threshold after which toolbar hides (in points).
    let hideThreshold: CGFloat

    /// Distance scrolled up before showing toolbar again.
    let showThreshold: CGFloat

    /// Animation duration for show/hide transitions.
    let animationDuration: TimeInterval

    /// Minimum delay between visibility changes (debounce).
    let debounceInterval: TimeInterval

    private var lastScrollOffset: CGFloat = 0
    private var accumulatedScrollUp: CGFloat = 0
    private var lastVisibilityChange: Date = .distantPast
    private var isAtTop: Bool = true

    init(
        hideThreshold: CGFloat = 50,
        showThreshold: CGFloat = 30,
        animationDuration: TimeInterval = 0.25,
        debounceInterval: TimeInterval = 0.1
    ) {
        self.hideThreshold = hideThreshold
        self.showThreshold = showThreshold
        self.animationDuration = animationDuration
        self.debounceInterval = debounceInterval
    }

    /// Call this when scroll position changes.
    /// - Parameters:
    ///   - offset: Current scroll offset (0 = top)
    ///   - contentHeight: Total content height
    ///   - visibleHeight: Visible viewport height
    func updateScroll(offset: CGFloat, contentHeight: CGFloat, visibleHeight: CGFloat) {
        let delta = offset - lastScrollOffset
        lastScrollOffset = offset
        isAtTop = offset <= hideThreshold

        // Always show at top
        if isAtTop, !isVisible {
            setVisible(true)
            accumulatedScrollUp = 0
            return
        }

        // Debounce rapid changes
        let now = Date()
        guard now.timeIntervalSince(lastVisibilityChange) >= debounceInterval else { return }

        if delta > 0 {
            // Scrolling down
            accumulatedScrollUp = 0
            if offset > hideThreshold, isVisible {
                setVisible(false)
            }
        } else if delta < 0 {
            // Scrolling up
            accumulatedScrollUp += abs(delta)
            if accumulatedScrollUp >= showThreshold, !isVisible {
                setVisible(true)
            }
        }
    }

    /// Explicitly show toolbar (e.g., when mouse enters toolbar area).
    func show() {
        if !isVisible {
            setVisible(true)
            accumulatedScrollUp = 0
        }
    }

    /// Reset state (e.g., when changing documents).
    func reset() {
        lastScrollOffset = 0
        accumulatedScrollUp = 0
        isAtTop = true
        setVisible(true)
    }

    private func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        lastVisibilityChange = Date()
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
