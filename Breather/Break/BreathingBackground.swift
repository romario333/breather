import SwiftUI

enum Palette {
    static let mist = Color(hex: 0xEAF3F0)
}

/// The colors of the break screen's mesh gradient, left to right and top to bottom.
/// The middle color drifts toward `glow` and back with each breath.
struct BreakTheme: Identifiable, Equatable {
    let name: String
    let grid: [UInt32]
    let glow: UInt32

    var id: String { name }
    var colors: [Color] { grid.map(Color.init(hex:)) }

    static let sunset = BreakTheme(name: "Sunset", grid: [
        0x1B1230, 0x3A1D45, 0x140E22,
        0x5C2448, 0x8E3B4F, 0x3A1D45,
        0xB0613E, 0x6E2C45, 0x1B1230,
    ], glow: 0xB65A4E)

    static let forest = BreakTheme(name: "Forest", grid: [
        0x0A1A14, 0x1C3A2C, 0x0D2226,
        0x234A33, 0x3B6B4A, 0x14363A,
        0x6B6232, 0x2A4A30, 0x08140F,
    ], glow: 0x5A8A60)

    static let deepBlue = BreakTheme(name: "Deep blue", grid: [
        0x050B22, 0x1A1F5E, 0x07102E,
        0x0E2A6B, 0x1E4E9E, 0x221C63,
        0x0A3A5C, 0x162C78, 0x040918,
    ], glow: 0x2F7AC4)

    static let lavender = BreakTheme(name: "Lavender dusk", grid: [
        0x2A2350, 0x4A3B7A, 0x1E1A3E,
        0x5A4A8E, 0x6E5A9E, 0x3A3A72,
        0xA2687A, 0x7A4E86, 0x2A2350,
    ], glow: 0x8A74B8)

    /// A break fades through the themes in this order. Neighbors are close in hue, so the fades stay clean.
    static let rotation = [sunset, lavender, deepBlue, forest]

    @MainActor private static var last: BreakTheme?

    /// A random theme to start a break with, never the one the last break started with.
    @MainActor static func next() -> BreakTheme {
        let pick = rotation.filter { $0 != last }.randomElement()!
        last = pick
        return pick
    }
}

/// A slow mesh gradient. The middle brightens and dims on a ten-second cycle, about one calm breath.
/// Over the break it fades through all the themes, starting with `theme`.
struct BreathingBackground: View {
    let theme: BreakTheme
    let since: Date
    var frozenAt: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let frozenAt {
            mesh(at: frozenAt)
        } else {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                mesh(at: context.date)
            }
        }
    }

    private func mesh(at date: Date) -> some View {
        let t = date.timeIntervalSinceReferenceDate
        let (grid, glow) = palette(elapsed: date.timeIntervalSince(since))
        func wave(_ period: Double, _ phase: Double) -> Float { Float(sin(t * 2 * .pi / period + phase)) }
        let breath = Double(wave(10, 0) + 1) / 2

        return MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5 + 0.2 * wave(19, 0), 0], [1, 0],
                [0, 0.5 + 0.2 * wave(17, 1)], [0.5 + 0.18 * wave(13, 2), 0.45 + 0.12 * wave(11, 3)], [1, 0.5 + 0.2 * wave(21, 4)],
                [0, 1], [0.5 + 0.2 * wave(23, 5), 1], [1, 1],
            ],
            colors: grid.enumerated().map { index, color in
                index == 4 ? color.mix(with: glow, by: 0.8 * breath) : color
            },
            smoothsColors: true
        )
        .overlay(Grain())
    }

    /// Each theme stays for a while, then fades into the next one.
    private func palette(elapsed: Double) -> (grid: [Color], glow: Color) {
        let hold = 55.0, fade = 20.0
        let rotation = BreakTheme.rotation
        let start = rotation.firstIndex(of: theme) ?? 0
        let step = Int(max(0, elapsed) / (hold + fade))
        let x = min(1, max(0, max(0, elapsed).truncatingRemainder(dividingBy: hold + fade) - hold) / fade)
        let progress = x * x * (3 - 2 * x)
        let from = rotation[(start + step) % rotation.count]
        let to = rotation[(start + step + 1) % rotation.count]
        return (
            zip(from.colors, to.colors).map { $0.mix(with: $1, by: progress) },
            Color(hex: from.glow).mix(with: Color(hex: to.glow), by: progress)
        )
    }
}

/// Fine noise keeps the large, dark gradient from banding.
private struct Grain: View {
    @MainActor private static let tile: NSImage = {
        let side = 128
        var pixels = [UInt8](repeating: 0, count: side * side)
        for index in pixels.indices { pixels[index] = UInt8.random(in: 0...255) }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let image = CGImage(
            width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: side,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
        return NSImage(cgImage: image, size: NSSize(width: side, height: side))
    }()

    var body: some View {
        Image(nsImage: Self.tile)
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity(0.05)
            .allowsHitTesting(false)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
