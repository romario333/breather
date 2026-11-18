import AppKit
import BreatherCore

/// A ring like the break screen's. The bright arc runs clockwise from the top and is the work left
/// before the next break. The faint arc is the work already done.
@MainActor
enum MenuBarIcon {
    private static let steps = 100
    private static var cache: [Int: NSImage] = [:]

    static func image(for phase: Phase, now: Date) -> NSImage {
        switch phase {
        case .paused:
            return symbol("pause.circle")
        case .onBreak:
            return ring(step: 0)
        case .working:
            return ring(step: Int((phase.remainingFraction(now: now) * Double(steps)).rounded(.up)))
        }
    }

    static func ring(step: Int) -> NSImage {
        if let cached = cache[step] { return cached }
        let fraction = Double(step) / Double(steps)
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { rect in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 6.4
            // A small gap on each side of the bright arc keeps the two arcs apart.
            let gap = 30.0
            let split = 360 * fraction

            func arc(from start: Double, to end: Double, width: CGFloat, alpha: CGFloat) {
                guard end - start > 1 else { return }
                let path = NSBezierPath()
                // Flipped view, so angles grow clockwise. -90 is the top.
                path.appendArc(withCenter: center, radius: radius,
                               startAngle: start - 90, endAngle: end - 90, clockwise: false)
                path.lineWidth = width
                path.lineCapStyle = .round
                NSColor.black.withAlphaComponent(alpha).setStroke()
                path.stroke()
            }

            switch fraction {
            case 1: arc(from: 0, to: 360, width: 2, alpha: 1)
            case 0: arc(from: 0, to: 360, width: 1.4, alpha: 0.4)
            default:
                arc(from: 0, to: split, width: 2, alpha: 1)
                arc(from: split + gap, to: 360 - gap, width: 1.4, alpha: 0.4)
            }
            return true
        }
        image.isTemplate = true
        cache[step] = image
        return image
    }

    private static func symbol(_ name: String) -> NSImage {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Breather")!
        image.isTemplate = true
        return image
    }
}
