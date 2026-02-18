import AppKit
import Foundation

struct JellyfishEntity {
    var x: Int
    var y: Double
    var driftX: Double  // slow horizontal drift
    var phase: Double
    var pulseSpeed: Double
    var verticalSpeed: Double
    var isDead: Bool = false
    var frameCounter: Int = 0

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var expandedArt:   [String] { ArtRepository.shared.jellyfishExpanded }
    static var contractedArt: [String] { ArtRepository.shared.jellyfishContracted }

    // Builtin fallbacks
    static let builtinExpandedArt: [String] = [
        " _.._ ",
        "'    '",
        " \\||/ ",
        "  ||  ",
        "  ||  ",
    ]
    static let builtinContractedArt: [String] = [
        " .__. ",
        "(    )",
        " /||\\ ",
        "  ||  ",
        "  /\\  ",
    ]

    static let width  = 6
    static let height = 5

    static let jellyColor  = NSColor(calibratedRed: 0.8, green: 0.5, blue: 1.0, alpha: 0.9)
    static let jellyColor2 = NSColor(calibratedRed: 0.6, green: 0.8, blue: 1.0, alpha: 0.9)

    mutating func tick(columns: Int, rows: Int) {
        frameCounter += 1
        phase += pulseSpeed

        // Jellyfish pulse: go up when contracting, drift down when expanding
        let pulse = sin(phase)
        if pulse > 0 {
            y -= verticalSpeed * 1.5  // rise during contraction
        } else {
            y += verticalSpeed * 0.5  // sink slightly during expansion
        }

        // Gentle horizontal drift
        let driftOffset = sin(phase * 0.3) * 0.05
        driftX += driftOffset

        // Remove if off screen
        if y < 2.0 || y > Double(rows - 3) {
            isDead = true
        }
    }

    func render(into grid: GridRenderer) {
        let pulse = sin(phase)
        let art = pulse > 0 ? JellyfishEntity.contractedArt : JellyfishEntity.expandedArt
        let color = frameCounter % 60 < 30 ? JellyfishEntity.jellyColor : JellyfishEntity.jellyColor2

        let col = x + Int(driftX.rounded())
        let row = Int(y.rounded())

        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: row + i, foreground: color)
        }
    }

    static func spawnRandom(columns: Int, sandTop: Int) -> JellyfishEntity {
        let x = Int.random(in: 3...(columns - JellyfishEntity.width - 3))
        let minY = 5.0
        let maxY = Double(sandTop - JellyfishEntity.height - 2)
        let y = Double.random(in: minY...maxY)

        return JellyfishEntity(
            x: x, y: y,
            driftX: 0,
            phase: Double.random(in: 0...(.pi * 2)),
            pulseSpeed: Double.random(in: 0.06...0.1),
            verticalSpeed: Double.random(in: 0.02...0.06)
        )
    }
}
