import SwiftUI

enum Palette {
    static let mist = Color(hex: 0xEAF3F0)
    static let ink = Color(hex: 0x07131C)
    static let deep = Color(hex: 0x0E2B3D)
    static let teal = Color(hex: 0x175A5D)
    static let seaGlass = Color(hex: 0x2F8C82)
    static let dusk = Color(hex: 0x30265C)
    static let plum = Color(hex: 0x472A57)
    static let ember = Color(hex: 0x7A4652)
}

/// A slow mesh gradient. The middle brightens and dims on a ten-second cycle, about one calm breath.
struct BreathingBackground: View {
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
            colors: [
                Palette.deep, Palette.dusk, Palette.ink,
                Palette.teal, Palette.teal.mix(with: Palette.seaGlass, by: 0.15 + 0.3 * breath), Palette.deep,
                Palette.ember, Palette.plum, Palette.ink,
            ],
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
