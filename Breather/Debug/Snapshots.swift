#if DEBUG
import AppKit
import SwiftUI

/// `-BreatherSnapshot <folder>` renders the break screen and settings to PNGs, then quits.
/// It checks layout without covering anyone's screen.
@MainActor
enum Snapshots {
    static func runIfRequested() {
        guard let path = UserDefaults.standard.string(forKey: "BreatherSnapshot") else { return }
        let dir = URL(filePath: path)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let now = Date()
        let content = BreakContent(since: now - 48, endsAt: now + 252, suggestion: "Look at something far away.", theme: .sunset)

        for (name, size, offset) in [("break", CGSize(width: 1440, height: 900), 0.0),
                                     ("break-later", CGSize(width: 1440, height: 900), 5.0),
                                     ("break-ultrawide", CGSize(width: 1720, height: 720), 0.0)] {
            let view = BreakView(content: content, onPostpone: {}, onSkip: {}, frozenAt: now + offset)
                .frame(width: size.width, height: size.height)
            capture(view, size: size, appearance: .darkAqua, to: dir.appending(path: "\(name).png"))
        }
        for (index, theme) in BreakTheme.rotation.enumerated() {
            var themed = content
            themed.theme = theme
            let view = BreakView(content: themed, onPostpone: {}, onSkip: {}, frozenAt: now)
                .frame(width: 1440, height: 900)
            capture(view, size: CGSize(width: 1440, height: 900), appearance: .darkAqua,
                    to: dir.appending(path: "theme-\(index + 1)-\(theme.name.lowercased().replacingOccurrences(of: " ", with: "-")).png"))
        }
        for appearance in [NSAppearance.Name.darkAqua, .aqua] {
            let name = appearance == .darkAqua ? "dark" : "light"
            capture(SettingsView().environment(AppModel()), size: CGSize(width: 440, height: 300), appearance: appearance,
                    to: dir.appending(path: "settings-\(name).png"))
        }
        let icons = VStack(spacing: 0) {
            ForEach([(Color(red: 0.2, green: 0.45, blue: 0.75), Color.white), (Color(white: 0.93), Color.black)], id: \.1) { background, ink in
                HStack(spacing: 14) {
                    ForEach([100, 80, 58, 30, 8, 0], id: \.self) { step in
                        Image(nsImage: MenuBarIcon.ring(step: step)).renderingMode(.template).foregroundStyle(ink)
                    }
                }
                .padding(8)
                .background(background)
            }
        }
        let renderer = ImageRenderer(content: icons)
        renderer.scale = 6
        if let image = renderer.cgImage {
            try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?
                .write(to: dir.appending(path: "menubar-icons.png"))
        }
        print("Snapshots written to \(dir.path)")
        exit(0)
    }

    /// Shaders, forms and canvases only draw inside a window.
    private static func capture(_ view: some View, size: CGSize, appearance: NSAppearance.Name, to url: URL) {
        let window = NSWindow(contentRect: CGRect(origin: CGPoint(x: -10000, y: -10000), size: size),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: appearance)
        window.backgroundColor = appearance == .darkAqua ? NSColor(white: 0.17, alpha: 1) : NSColor(white: 0.95, alpha: 1)
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(origin: .zero, size: size)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }
}
#endif
