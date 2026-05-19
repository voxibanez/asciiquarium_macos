// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit

struct SharkEntity {
    var x: Double
    var y: Int
    var direction: Direction
    var speed: Double
    var isDead: Bool = false
    var frameCounter: Int = 0

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var rightArt:  [String] { ArtRepository.shared.sharkRight }
    static var leftArt:   [String] { ArtRepository.shared.sharkLeft }
    static var width:     Int      { ArtRepository.shared.sharkWidth }
    static var height:    Int      { ArtRepository.shared.sharkHeight }

    // Builtin fallbacks
    static let builtinRightArt: [String] = [
        "                              __      ",
        "                             ( `\\     ",
        "  ,=========================)   `\\    ",
        ";' `.                      (     `\\__ ",
        " ;   `.             __..--''          `~~~~-._",
        "  `.   `.____...--''                       (b  `--._",
        "    >                     _.-'      .((      ._     )",
        "  .`.-`--...__         .-'     -.___.....-(|/|/|/|/'",
        " ;.'           ...----`.___.',,,_______......---'   ",
        " '           '-'                                    ",
    ]
    static let builtinLeftArt: [String] = [
        "      __                              ",
        "     /` )                             ",
        "    /`   (=========================,  ",
        " __/`     )                      .` ';",
        "_.-~~~~`          ``---..__             .   ;",
        " `--.  db)                       ``--....____.`   .'",
        "(     _.      )).      `-._                     <    ",
        " `\\|\\|\\|\\|)-.....___.-     `-.         __...--`-.`.",
        "   `---......_______,,,`.___.'----... .'           `.;",
        "                                     `-`           '  ",
    ]
    static let builtinWidth  = 56
    static let builtinHeight = 10

    mutating func tick(columns: Int, speedMultiplier: Double = 1.0) {
        x += speed * direction.sign * speedMultiplier
        frameCounter += 1

        let w = Double(SharkEntity.width)
        if direction == .right && x > Double(columns) + 5 {
            isDead = true
        } else if direction == .left && x < -w - 5 {
            isDead = true
        }
    }

    func render(into grid: GridRenderer) {
        let art = direction == .right ? SharkEntity.rightArt : SharkEntity.leftArt
        let (col, offset) = grid.colAndOffset(for: x)
        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: y + i, foreground: ColorPalette.shark, xOffset: offset)
        }
    }

    // Check if a fish overlaps with the shark's body
    func eats(fish: FishEntity) -> Bool {
        let sharkCol = Int(x.rounded())
        let fishCol = Int(fish.x.rounded())

        let sharkRight = sharkCol + SharkEntity.width
        let fishRight = fishCol + fish.design.width
        let sharkBottom = y + SharkEntity.height

        let horizontalOverlap = fishCol < sharkRight && fishRight > sharkCol
        let verticalOverlap = fish.y < sharkBottom && (fish.y + fish.design.height) > y

        return horizontalOverlap && verticalOverlap
    }

    static func spawnRandom(sandTop: Int) -> SharkEntity {
        let direction: Direction = .right
        let x: Double = Double(-SharkEntity.width - 5)
        let speed = Double.random(in: 0.3...0.5)
        let minY = 6
        let maxY = max(minY, sandTop - SharkEntity.height - 2)
        let y = Int.random(in: minY...maxY)

        return SharkEntity(x: x, y: y, direction: direction, speed: speed)
    }
}
