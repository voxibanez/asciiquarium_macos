// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit

struct ShipEntity {
    var x: Double
    var direction: Direction
    var speed: Double
    var isDead: Bool = false

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var rightArt: [String] { ArtRepository.shared.shipRight }
    static var leftArt:  [String] { ArtRepository.shared.shipLeft }
    static var width:    Int      { ArtRepository.shared.shipWidth }
    static var height:   Int      { ArtRepository.shared.shipHeight }

    // Builtin fallbacks
    static let builtinRightArt: [String] = [
        "     |    |    |    ",
        "    )_)  )_)  )_)  ",
        "   )___))___))___)\\",
        "  )____)____)_____)\\\\",
        "_____|____|____|____\\\\\\",
        "\\                   /  ",
    ]
    static let builtinLeftArt: [String] = [
        "      |    |    |      ",
        "    (_(  (_(  (_(      ",
        "  /(___((___((___(     ",
        "//(_____(____(____(    ",
        "__///____|____|____|_____",
        "   \\                   / ",
    ]
    static let builtinWidth  = 25
    static let builtinHeight = 6

    mutating func tick(columns: Int, speedMultiplier: Double = 1.0) {
        x += speed * direction.sign * speedMultiplier

        let w = Double(ShipEntity.width)
        if direction == .right && x > Double(columns) + 5 {
            isDead = true
        } else if direction == .left && x < -w - 5 {
            isDead = true
        }
    }

    func render(into grid: GridRenderer, waterRow: Int) {
        let art = direction == .right ? ShipEntity.rightArt : ShipEntity.leftArt
        let (col, offset) = grid.colAndOffset(for: x)
        let startRow = waterRow - ShipEntity.height + 2

        for (i, line) in art.enumerated() {
            let row = startRow + i
            let color = i < 3 ? ColorPalette.shipSail : ColorPalette.ship
            grid.putString(line, at: col, row: row, foreground: color, xOffset: offset)
        }
    }

    static func spawnRandom(columns: Int) -> ShipEntity {
        let direction: Direction = Bool.random() ? .left : .right
        let x: Double = direction == .right ? Double(-ShipEntity.width - 2) : Double(columns + 2)
        let speed = Double.random(in: 0.15...0.3)

        return ShipEntity(x: x, direction: direction, speed: speed)
    }
}
