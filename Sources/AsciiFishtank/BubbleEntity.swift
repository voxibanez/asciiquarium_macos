// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit
import Foundation

struct BubbleEntity {
    var x: Double
    var y: Double
    var speed: Double
    var character: Character
    var isDead: Bool = false

    mutating func tick(columns: Int, bottomRow: Int, speedMultiplier: Double = 1.0) {
        let distance = speed * speedMultiplier
        y -= distance

        switch Int.random(in: 0..<10) {
        case 0:
            x -= distance
        case 1:
            x += distance
        default:
            break
        }

        x = min(max(x, 1.0), Double(columns - 2))
        y = min(y, Double(bottomRow - 1))

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
        let (col, offset) = grid.colAndOffset(for: x)
        grid.putChar(character, at: col, row: Int(y.rounded()), foreground: ColorPalette.bubble, xOffset: offset)
    }

    static func spawnRandom(columns: Int, bottomRow: Int) -> BubbleEntity {
        let x = Double.random(in: 2.0...Double(columns - 3))
        let chars: [Character] = ["o", "O", ".", "o", "o", "\u{00B0}"]
        let ch = chars.randomElement()!
        let speed = Double.random(in: 0.05...0.18)

        return BubbleEntity(
            x: x,
            y: Double(bottomRow - 1),
            speed: speed,
            character: ch
        )
    }

    // Spawn a small bubble at a specific position (from a fish's mouth)
    static func spawnAt(col: Int, row: Int) -> BubbleEntity {
        let chars: [Character] = [".", "o", "o"]
        return BubbleEntity(
            x: Double(col),
            y: Double(row),
            speed: Double.random(in: 0.06...0.14),
            character: chars.randomElement()!
        )
    }
}
