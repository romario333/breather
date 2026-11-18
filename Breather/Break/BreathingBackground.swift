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

    /// Each break gets the next theme in this list.
    static let rotation = [sunset, forest, deepBlue, lavender]

    /// The next theme in the rotation. It carries on where it left off after a relaunch.
    @MainActor static func next(defaults: UserDefaults = .standard) -> BreakTheme {
        let index = defaults.integer(forKey: "themeIndex") % rotation.count
        defaults.set(index + 1, forKey: "themeIndex")
        return rotation[index]
    }
}

/// A slow mesh gradient. The middle brightens and dims on a ten-second cycle, about one calm breath.
struct BreathingBackground: View {
    let theme: BreakTheme
    var frozenAt: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let frozenAt {
            mesh(at: frozenAt.timeIntervalSinceReferenceDate)
        } else {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                mesh(at: context.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func mesh(at t: Double) -> some View {
        func wave(_ period: Double, _ phase: Double) -> Float { Float(sin(t * 2 * .pi / period + phase)) }
        let breath = Double(wave(10, 0) + 1) / 2

        return MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5 + 0.10 * wave(23, 0), 0], [1, 0],
                [0, 0.5 + 0.10 * wave(19, 1)], [0.5 + 0.09 * wave(17, 2), 0.45 + 0.07 * wave(13, 3)], [1, 0.5 + 0.10 * wave(21, 4)],
                [0, 1], [0.5 + 0.12 * wave(29, 5), 1], [1, 1],
            ],
            colors: theme.colors.enumerated().map { index, color in
                index == 4 ? color.mix(with: Color(hex: theme.glow), by: 0.15 + 0.3 * breath) : color
            },
            smoothsColors: true
        )
        .overlay(Grain())
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
