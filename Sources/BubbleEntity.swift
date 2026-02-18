import AppKit
import Foundation

struct BubbleEntity {
    var baseX: Int
    var x: Int
    var y: Double
    var speed: Double
    var character: Character
    var wobbleAmplitude: Double
    var wobblePhase: Double
    var wobbleSpeed: Double
    var isDead: Bool = false

    mutating func tick(speedMultiplier: Double = 1.0) {
        y -= speed * speedMultiplier  // rise upward (row 0 = top)
        wobblePhase += wobbleSpeed
        x = baseX + Int((sin(wobblePhase) * wobbleAmplitude).rounded())

        // Reached the surface
        if y < 1.0 {
            isDead = true
            return
        }

        // Random chance to pop before reaching surface (~0.5% per frame).
        // Reuse a single Double.random call (slightly cheaper than Int.random).
        if Double.random(in: 0..<1) < 0.005 {
            isDead = true
        }
    }

    func render(into grid: GridRenderer) {
        let row = Int(y.rounded())
        grid.putChar(character, at: x, row: row, foreground: ColorPalette.bubble)
    }

    static func spawnRandom(columns: Int, bottomRow: Int) -> BubbleEntity {
        let x = Int.random(in: 2...(columns - 3))
        let chars: [Character] = ["o", "O", ".", "o", "o", "\u{00B0}"]
        let ch = chars.randomElement()!
        let speed = Double.random(in: 0.05...0.18)
        let wobbleAmp = Double.random(in: 0.0...1.5)

        return BubbleEntity(
            baseX: x, x: x,
            y: Double(bottomRow - 1),
            speed: speed,
            character: ch,
            wobbleAmplitude: wobbleAmp,
            wobblePhase: Double.random(in: 0.0...(.pi * 2)),
            wobbleSpeed: Double.random(in: 0.05...0.15)
        )
    }

    // Spawn a small bubble at a specific position (from a fish's mouth)
    static func spawnAt(col: Int, row: Int) -> BubbleEntity {
        let chars: [Character] = [".", "o", "o"]
        return BubbleEntity(
            baseX: col, x: col,
            y: Double(row),
            speed: Double.random(in: 0.06...0.14),
            character: chars.randomElement()!,
            wobbleAmplitude: Double.random(in: 0.3...1.0),
            wobblePhase: Double.random(in: 0.0...(.pi * 2)),
            wobbleSpeed: Double.random(in: 0.06...0.12)
        )
    }
}
