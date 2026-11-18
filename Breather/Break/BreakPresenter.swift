import AppKit
import SwiftUI

struct BreakContent: Equatable {
    var since: Date
    var endsAt: Date
    var suggestion: String
}

/// Covers every screen with a borderless panel above everything, including full-screen apps.
@MainActor
final class BreakPresenter {
    var onPostpone: () -> Void = {}
    var onSkip: () -> Void = {}

    private var content: BreakContent?
    private var shownAt = Date()
    private var panels: [BreakPanel] = []
    private var keyMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    init() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.panels.isEmpty else { return }
                self.removePanels(animated: false)
                self.openPanels(animated: false)
            }
        }
    }

    func show(since: Date, endsAt: Date) {
        if let content, content.since == since, content.endsAt == endsAt { return }
        let isNew = content == nil
        content = BreakContent(since: since, endsAt: endsAt, suggestion: content?.suggestion ?? Suggestions.next())
        if isNew { shownAt = Date() }
        removePanels(animated: false)
        openPanels(animated: isNew)
    }

    func hide() {
        guard content != nil else { return }
        content = nil
        removePanels(animated: true)
    }

    private func openPanels(animated: Bool) {
        guard let content else { return }
        let mouse = NSEvent.mouseLocation
        let keyScreen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        for screen in NSScreen.screens {
            let panel = BreakPanel(screen: screen)
            let view = BreakView(
                content: content,
                onPostpone: { [weak self] in self?.onPostpone() },
                onSkip: { [weak self] in self?.onSkip() }
            )
            panel.contentView = FirstClickHostingView(rootView: view)
            panel.alphaValue = animated ? 0 : 1
            panel.orderFrontRegardless()
            if screen == keyScreen { panel.makeKey() }
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 1.2
                    panel.animator().alphaValue = 1
                }
            }
            panels.append(panel)
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = event.keyCode
            let modifiers = event.modifierFlags
            let handled = MainActor.assumeIsolated {
                self?.handleKey(keyCode: keyCode, modifiers: modifiers) ?? false
            }
            return handled ? nil : event
        }
    }

    private func removePanels(animated: Bool) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        let closing = panels
        panels = []
        guard animated else {
            for panel in closing { panel.orderOut(nil) }
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.6
            for panel in closing { panel.animator().alphaValue = 0 }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.65))
            for panel in closing { panel.orderOut(nil) }
        }
    }

    /// Esc postpones. Keys typed in the first moment were meant for the app you were in.
    private func handleKey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        guard !panels.isEmpty, modifiers.intersection([.command, .control, .option]).isEmpty else { return false }
        guard Date().timeIntervalSince(shownAt) > 1 else { return true }
        if keyCode == 53 {
            onPostpone()
        }
        return true
    }
}

final class BreakPanel: NSPanel {
    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isFloatingPanel = true
        // After isFloatingPanel, which resets the level to floating.
        level = .screenSaver
        hidesOnDeactivate = false
        isMovable = false
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        isReleasedWhenClosed = false
        setFrame(screen.frame, display: false)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Buttons on a screen that isn't key should work on the first click.
final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

enum Suggestions {
    static let all = [
        "Stand up and stretch.",
        "Look at something far away.",
        "Get a glass of water.",
        "Walk around for a bit.",
        "Roll your shoulders and breathe out slowly.",
        "Open a window.",
        "Close your eyes for a minute.",
    ]

    @MainActor private static var last: String?

    @MainActor static func next() -> String {
        let pick = all.filter { $0 != last }.randomElement()!
        last = pick
        return pick
    }
}
