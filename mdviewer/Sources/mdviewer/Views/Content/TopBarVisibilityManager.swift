//
//  TopBarVisibilityManager.swift
//  mdviewer
//

internal import SwiftUI

/// Manages top bar visibility state with auto-hide behavior.
///
/// Encapsulates all state and logic for the floating top bar's
/// show/hide animations, idle detection, and hover interactions.
@MainActor
@Observable
final class TopBarVisibilityManager {
    // MARK: - State

    var isVisible = true
    var showAppearancePopover = false
    var isHoveringTopBar = false
    var isHoveringRevealZone = false
    var lastInteractionAt = Date()

    // MARK: - Private State

    private var idleHideTask: Task<Void, Never>?
    private let idleDelay: TimeInterval

    // MARK: - Initialization

    init(idleDelay: TimeInterval = DesignTokens.Animation.idleDelay) {
        self.idleDelay = idleDelay
    }

    // MARK: - Computed Properties

    var shouldShow: Bool {
        isVisible || showAppearancePopover || isHoveringTopBar || isHoveringRevealZone
    }

    // MARK: - Actions

    func reveal() {
        idleHideTask?.cancel()
        idleHideTask = nil
        withAnimation(.easeInOut(duration: DesignTokens.Animation.normal)) {
            isVisible = true
        }
    }

    func scheduleHide(shouldSkipAnimation: Bool = false) {
        idleHideTask?.cancel()

        guard !showAppearancePopover, !isHoveringTopBar, !isHoveringRevealZone else { return }

        let elapsed = Date().timeIntervalSince(lastInteractionAt)
        let delay = max(0.12, idleDelay - elapsed)

        idleHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard !self.isHoveringTopBar, !self.isHoveringRevealZone, !self.showAppearancePopover else { return }

            if Date().timeIntervalSince(lastInteractionAt) < idleDelay {
                self.scheduleHide(shouldSkipAnimation: shouldSkipAnimation)
                return
            }

            withAnimation(.easeInOut(duration: DesignTokens.Animation.topBar)) {
                self.isVisible = false
            }
        }
    }

    func registerInteraction() {
        lastInteractionAt = Date()
        reveal()
        scheduleHide()
    }

    func handlePopoverChange(isPresented: Bool) {
        if isPresented {
            reveal()
        } else {
            scheduleHide()
        }
    }

    func cleanup() {
        idleHideTask?.cancel()
        idleHideTask = nil
    }
}
