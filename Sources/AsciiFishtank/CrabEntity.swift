// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit
import Foundation

struct CrabEntity {
    var x: Double
    var baseRow: Int  // topmost row the crab occupies
    var direction: Direction
    var speed: Double
    var pauseTimer: Int = 0
    var frameCounter: Int = 0
    var animFrame: Int = 0

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var rightFrames: [[String]] { ArtRepository.shared.crabRightFrames }
    static var leftFrames:  [[String]] { ArtRepository.shared.crabLeftFrames }
    static var width:       Int        { ArtRepository.shared.crabWidth }
    static var height:      Int        { ArtRepository.shared.crabHeight }

    // Builtin fallbacks
    static let builtinRightFrames: [[String]] = [
        [
            " ,v  /)",
            "(o  o) ",
            " /| |\\ ",
        ],
        [
            " ,v  /)",
            "(o  o) ",
            "/ | | \\",
        ],
    ]
    static let builtinLeftFrames: [[String]] = [
        [
            "(\\  v, ",
            " (o  o)",
            " /| |\\ ",
        ],
        [
            "(\\  v, ",
            " (o  o)",
            "/ | | \\",
        ],
    ]
    static let builtinWidth  = 7
    static let builtinHeight = 3

    static let crabColor = NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)

    mutating func tick(columns: Int, speedMultiplier: Double = 1.0) {
        frameCounter += 1

        // Occasionally pause to look around
        if pauseTimer > 0 {
            pauseTimer -= 1
            return
        }

        if Double.random(in: 0..<1) < 0.0125 {  // ~1/80
            pauseTimer = Int.random(in: 15...60)
            if Bool.random() {
                direction = direction == .left ? .right : .left
            }
        }

        x += speed * direction.sign * speedMultiplier

        // Walk animation - scuttle legs
        if frameCounter % 5 == 0 {
            let frames = CrabEntity.rightFrames
            animFrame = (animFrame + 1) % max(1, frames.count)
        }

        // Bounce at edges
        if x < 1 {
            direction = .right
        } else if x > Double(columns - CrabEntity.width - 1) {
            direction = .left
        }
    }

    func render(into grid: GridRenderer) {
        let frames = direction == .right ? CrabEntity.rightFrames : CrabEntity.leftFrames
        let art = frames[animFrame % max(1, frames.count)]
        let (col, offset) = grid.colAndOffset(for: x)
        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: baseRow + i, foreground: CrabEntity.crabColor, xOffset: offset)
        }
    }

    static func spawnRandom(columns: Int, sandRow: Int) -> CrabEntity {
        let x = Double.random(in: 2.0...Double(columns - CrabEntity.width - 2))
        let direction: Direction = Bool.random() ? .left : .right
        let speed = Double.random(in: 0.08...0.2)

        return CrabEntity(
            x: x,
            baseRow: sandRow - CrabEntity.height,
            direction: direction,
            speed: speed
        )
    }
}
