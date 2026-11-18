import BreatherCore
import SwiftUI

/// The break screen: a dotted ring that empties as the break runs out, one suggestion and two ways out.
/// Sizes are in units of a hundredth of the screen width, so the layout scales with the screen.
struct BreakView: View {
    let content: BreakContent
    let onPostpone: () -> Void
    let onSkip: () -> Void
    /// A fixed time for snapshots. The live screen follows the clock.
    var frozenAt: Date?

    var body: some View {
        GeometryReader { geometry in
            let u = min(geometry.size.width / 100, geometry.size.height / 62.5)
            ZStack {
                BreathingBackground(theme: content.theme, since: content.since, frozenAt: frozenAt)
                column(u: u)
                    // The ring sits a little above the middle, so the whole column looks centered.
                    .offset(y: 2 * u)
                BreakMenu(content: content, u: u)
                    .padding(2.4 * u)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .foregroundStyle(Palette.mist)
        .fontDesign(.rounded)
        .ignoresSafeArea()
    }

    private func column(u: CGFloat) -> some View {
        VStack(spacing: 0) {
            clock { now in
                ZStack {
                    DottedRing(fraction: fraction(at: now), u: u)
                    Text(Format.countdown(content.endsAt.timeIntervalSince(now)))
                        .font(.system(size: 7.6 * u, weight: .light))
                        .monospacedDigit()
                        .tracking(-0.01 * 7.6 * u)
                }
                .frame(width: 30 * u, height: 30 * u)
            }
            Text(content.suggestion)
                .font(.system(size: 1.9 * u))
                .opacity(0.8)
                .padding(.top, 4.4 * u)
            HStack(spacing: 1.2 * u) {
                GlassButton(title: "Postpone 5 min", u: u, action: onPostpone)
                GlassButton(title: "Skip break", u: u, action: onSkip)
            }
            .padding(.top, 3.6 * u)
        }
    }

    @ViewBuilder
    private func clock(@ViewBuilder _ content: @escaping (Date) -> some View) -> some View {
        if let frozenAt {
            content(frozenAt)
        } else {
            TimelineView(.animation(minimumInterval: 0.1)) { context in content(context.date) }
        }
    }

    private func fraction(at now: Date) -> Double {
        Phase.onBreak(since: content.since, endsAt: content.endsAt).remainingFraction(now: now)
    }
}

/// Dots run clockwise from the top. Lit dots are the break still ahead.
private struct DottedRing: View {
    let fraction: Double
    let u: CGFloat

    private let count = 120

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - u
            let dot = 0.34 * u
            let lit = fraction * Double(count)

            func path(_ index: Int, scale: CGFloat = 1) -> Path {
                let angle = Double(index) / Double(count) * 2 * .pi - .pi / 2
                let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                let d = dot * scale
                return Path(ellipseIn: CGRect(x: point.x - d / 2, y: point.y - d / 2, width: d, height: d))
            }
            // How lit each dot is. The dot at the edge fades out smoothly.
            func level(_ index: Int) -> Double { min(1, max(0, lit - Double(index))) }

            for index in 0..<count where level(index) < 1 {
                context.fill(path(index), with: .color(Palette.mist.opacity(0.16)))
            }
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: 0.5 * u))
                for index in 0..<count where level(index) > 0 {
                    glow.fill(path(index, scale: 1.6), with: .color(Palette.mist.opacity(0.35 * level(index))))
                }
            }
            for index in 0..<count where level(index) > 0 {
                context.fill(path(index), with: .color(Palette.mist.opacity(0.16 + 0.84 * level(index))))
            }
        }
    }
}

/// The menu bar menu, for when the break screen covers the menu bar.
/// It shows only while the mouse moves, so it stays out of the way while you rest.
private struct BreakMenu: View {
    let content: BreakContent
    let u: CGFloat
    @State private var mouseMoved = false
    @State private var hovering = false

    private var shown: Bool { mouseMoved || hovering }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: !shown)) { context in
            Menu {
                MenuContent()
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 1.4 * u, weight: .light))
                    .foregroundStyle(tint(at: context.date))
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Breather menu")
        }
        .opacity(shown ? 1 : 0)
        .animation(.easeInOut(duration: 0.6), value: shown)
        .onHover { hovering = $0 }
        .task { await watchMouse() }
    }

    /// The gradient's color in the top-right corner, where the icon sits, lifted so the icon stands out.
    private func tint(at date: Date) -> Color {
        let (from, to, progress) = BreakTheme.fade(startingWith: content.theme, elapsed: date.timeIntervalSince(content.since))
        let corner = OKLab(hex: from.grid[2]).mixed(with: OKLab(hex: to.grid[2]), by: progress)
        return corner.contrasting.color
    }

    /// Polling sees the mouse on every screen, whichever panel is key.
    private func watchMouse() async {
        var last = NSEvent.mouseLocation
        var movedAt = Date.distantPast
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(200))
            let location = NSEvent.mouseLocation
            if location != last {
                last = location
                movedAt = Date()
            }
            mouseMoved = Date().timeIntervalSince(movedAt) < 3
        }
    }
}

/// Both ways out look the same. Taking the break means pressing neither.
private struct GlassButton: View {
    let title: String
    let u: CGFloat
    let action: () -> Void
    @State private var hovering = false

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 1.6 * u, style: .continuous) }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 1.35 * u, weight: .medium))
                .padding(.vertical, 0.8 * u)
                .padding(.horizontal, 1.9 * u)
                .background(Palette.mist.opacity(hovering ? 0.2 : 0.11), in: shape)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}
