// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit
import Foundation

struct SeaweedEntity {
    var baseX: Int
    var baseRow: Int  // bottom of the seaweed (on the sand)
    var height: Int
    var phase: Double
    var speed: Double
    var color: NSColor

    // Characters for seaweed segments
    static let tipChars: [Character] = ["~", "*", ")", "("]
    static let stalkLeft: Character = "("
    static let stalkRight: Character = ")"
    static let stalkStraight: Character = "|"

    mutating func tick() {
        phase += speed
    }

    func render(into grid: GridRenderer) {
        let invHeightM1 = 1.0 / Double(max(1, height - 1))
        for i in 0..<height {
            let segmentRow = baseRow - i  // grow upward
            guard segmentRow >= 1 else { continue }

            // Sway increases toward the tip
            let swayFactor = Double(i) * invHeightM1
            let offset = Int((sin(phase + Double(i) * 0.6) * swayFactor * 1.5).rounded())
            let col = baseX + offset

            let ch: Character
            if i == height - 1 {
                // Tip
                ch = SeaweedEntity.tipChars[abs(baseX) % SeaweedEntity.tipChars.count]
            } else if offset > 0 {
                ch = SeaweedEntity.stalkRight
            } else if offset < 0 {
                ch = SeaweedEntity.stalkLeft
            } else {
                ch = SeaweedEntity.stalkStraight
            }

            grid.putChar(ch, at: col, row: segmentRow, foreground: color)
        }
    }

    static func spawnRandom(baseRow: Int, columns: Int) -> SeaweedEntity {
        let x = Int.random(in: 3...(columns - 4))
        let height = Int.random(in: 3...8)
        let color = ColorPalette.seaweedColors.randomElement()!
        let speed = Double.random(in: 0.02...0.06)
        let phase = Double.random(in: 0.0...(.pi * 2))

        return SeaweedEntity(
            baseX: x, baseRow: baseRow, height: height,
            phase: phase, speed: speed, color: color)
    }
}
