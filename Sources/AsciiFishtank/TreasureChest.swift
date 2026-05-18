// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit
import Foundation

struct TreasureChest {
    var col: Int
    var row: Int
    var frameCounter: Int = 0
    var isOpen: Bool = false
    var openTimer: Int = 0
    var glintPhase: Double = 0

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var closedArt: [String] { ArtRepository.shared.chestClosed }
    static var openArt:   [String] { ArtRepository.shared.chestOpen }

    // Builtin fallbacks
    static let builtinClosedArt: [String] = [
        " _____ ",
        "|  _  |",
        "|_|_|_|",
    ]
    static let builtinOpenArt: [String] = [
        " _---_ ",
        "/ ___ \\",
        "|[___]|",
    ]

    // Glint characters that appear above when open
    static let glintChars: [Character] = ["*", "+", ".", "'"]

    static let width  = 7
    static let height = 3

    static let chestColor = NSColor(calibratedRed: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
    static let goldColor  = NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
    static let glintColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)

    mutating func tick() {
        frameCounter += 1
        glintPhase += 0.08

        if isOpen {
            openTimer -= 1
            if openTimer <= 0 {
                isOpen = false
            }
        } else {
            // Occasionally open (~every 20-30 seconds)
            if Int.random(in: 0..<(15 * 25)) == 0 {
                isOpen = true
                openTimer = Int.random(in: 45...90)  // stay open 3-6 seconds
            }
        }
    }

    func render(into grid: GridRenderer) {
        let art   = isOpen ? TreasureChest.openArt   : TreasureChest.closedArt
        let color = isOpen ? TreasureChest.goldColor  : TreasureChest.chestColor

        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: row + i, foreground: color)
        }

        // Render glint sparkles above when open
        if isOpen {
            let glint1 = sin(glintPhase) > 0.3
            let glint2 = sin(glintPhase * 1.3 + 1.0) > 0.4
            let glint3 = sin(glintPhase * 0.7 + 2.0) > 0.5

            if glint1 && row - 1 >= 1 {
                let ch = TreasureChest.glintChars[frameCounter % TreasureChest.glintChars.count]
                grid.putChar(ch, at: col + 3, row: row - 1, foreground: TreasureChest.glintColor)
            }
            if glint2 && row - 2 >= 1 {
                let ch = TreasureChest.glintChars[(frameCounter + 1) % TreasureChest.glintChars.count]
                grid.putChar(ch, at: col + 1, row: row - 2, foreground: TreasureChest.glintColor)
            }
            if glint3 && row - 1 >= 1 {
                let ch = TreasureChest.glintChars[(frameCounter + 2) % TreasureChest.glintChars.count]
                grid.putChar(ch, at: col + 5, row: row - 1, foreground: TreasureChest.glintColor)
            }
        }
    }
}
