import AppKit
import BreatherCore

/// A small version of the break screen's ring. Lit dots are the work left before the next break.
@MainActor
enum MenuBarIcon {
    private static let dots = 12
    private static var cache: [Int: NSImage] = [:]

    static func image(for phase: Phase, now: Date) -> NSImage {
        switch phase {
        case .paused:
            return symbol("pause.circle")
        case .onBreak:
            return ring(lit: 0)
        case .working:
            let lit = Int((phase.remainingFraction(now: now) * Double(dots)).rounded(.up))
            return ring(lit: lit)
        }
    }

    private static func ring(lit: Int) -> NSImage {
        if let cached = cache[lit] { return cached }
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { rect in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 6.6
            for index in 0..<dots {
                let angle = Double(index) / Double(dots) * 2 * .pi - .pi / 2
                let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                let isLit = index < lit
                let d: CGFloat = isLit ? 2.6 : 1.8
                NSColor.black.withAlphaComponent(isLit ? 1 : 0.35).setFill()
                NSBezierPath(ovalIn: CGRect(x: point.x - d / 2, y: point.y - d / 2, width: d, height: d)).fill()
            }
            return true
        }
        image.isTemplate = true
        cache[lit] = image
        return image
    }

    private static func symbol(_ name: String) -> NSImage {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Breather")!
        image.isTemplate = true
        return image
    }
}
