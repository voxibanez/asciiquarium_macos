// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit
import Foundation

struct WhaleEntity {
    var x: Double
    var y: Int
    var direction: Direction
    var speed: Double
    var isDead: Bool = false
    var frameCounter: Int = 0
    var spoutFrame: Int = 0  // 0 = no spout, 1+ = spout animation

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var rightArt:    [String]   { ArtRepository.shared.whaleRightBody }
    static var leftArt:     [String]   { ArtRepository.shared.whaleLeftBody }
    static var spoutFrames: [[String]] { ArtRepository.shared.whaleSpoutFrames }
    static var width:       Int        { ArtRepository.shared.whaleWidth }

    // Builtin fallbacks
    static let builtinRightArt: [String] = [
        "        .-----:   ",
        "      .'       `. ",
        ",    /       (o) \\",
        "\\`._/          ,__)",
    ]
    static let builtinLeftArt: [String] = [
        "   :-----.        ",
        " .'       `.      ",
        "/ (o)       \\    ,",
        "(__,          \\_.'/ ",
    ]
    static let builtinSpoutFrames: [[String]] = [
        [],
        ["   :"],
        ["  . .", "  -:-", "   :"],
        ["  . .", " .-:-.", "   :"],
        ["  . .", " '.-:-.`", " '  :  '"],
        ["  .- -.", " ;  :  ;"],
        [" ;     ;"],
    ]
    static let builtinWidth  = 20

    static let spoutCycleLength = 60  // frames per spout cycle

    mutating func tick(columns: Int, speedMultiplier: Double = 1.0) {
        x += speed * direction.sign * speedMultiplier
        frameCounter += 1

        // Spout animation cycle
        let frames = WhaleEntity.spoutFrames
        let cyclePos = frameCounter % WhaleEntity.spoutCycleLength
        if cyclePos < 30 {
            spoutFrame = 0  // no spout for first half
        } else {
            let spoutPos = (cyclePos - 30) / 5
            spoutFrame = min(spoutPos + 1, frames.count - 1)
        }

        let w = Double(WhaleEntity.width)
        if direction == .right && x > Double(columns) + 5 {
            isDead = true
        } else if direction == .left && x < -w - 5 {
            isDead = true
        }
    }

    func render(into grid: GridRenderer) {
        let art = direction == .right ? WhaleEntity.rightArt : WhaleEntity.leftArt
        let (col, offset) = grid.colAndOffset(for: x)

        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: y + i, foreground: ColorPalette.whale, xOffset: offset)
        }

        let frames = WhaleEntity.spoutFrames
        if spoutFrame > 0 && spoutFrame < frames.count {
            let spout = frames[spoutFrame]
            let spoutX = col + (direction == .right ? 8 : 5)
            for (i, line) in spout.enumerated() {
                let spoutRow = y - spout.count + i
                if spoutRow >= 1 {
                    grid.putString(line, at: spoutX, row: spoutRow,
                                   foreground: ColorPalette.bubble, xOffset: offset)
                }
            }
        }
    }

    static func spawnRandom(columns: Int) -> WhaleEntity {
        let direction: Direction = Bool.random() ? .left : .right
        let x: Double = direction == .right ? Double(-WhaleEntity.width - 3) : Double(columns + 3)
        let speed = Double.random(in: 0.12...0.25)
        // Whale sits at the water surface (rows 1-3 are water, whale body starts just below)
        let y = 1

        return WhaleEntity(x: x, y: y, direction: direction, speed: speed)
    }
}
