// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit

struct Decoration {
    let art: [String]
    let col: Int
    let row: Int
    let color: NSColor
}

class DecorationEntity {
    let columns: Int
    let rows: Int
    let sandRow: Int  // topmost sand row
    var sandChars: [[Character]] = []
    var objects: [Decoration] = []

    static let castleArt: [String] = [
        "               T~~",
        "               |  ",
        "              /^\\ ",
        "             /   \\",
        " _   _   _  /     \\  _   _   _",
        "[ ]_[ ]_[ ]/ _   _ \\[ ]_[ ]_[ ]",
        "|_=__-_ =_|_[ ]_[ ]_|_=-___-__|",
        " | _- =  | =_ = _    |= _=   |",
        " |= -[]  |- = _ =    |_-=_[] |",
        " | =_    |= - ___    | =_ =  |",
        " |=  []- |-  /| |\\   |=_ =[] |",
        " |- =_   | =| | | |  |- = -  |",
        " |_______|__|_|_|_|__|_______|",
    ]

    static let castleWidth = 31
    static let castleHeight = 13

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        self.sandRow = rows - 3

        generateSand()
        generateDecorations()
    }

    private func generateSand() {
        let chars: [Character] = [".", ",", ";", "'", ":", "`", ".", ",", "~"]
        for _ in sandRow..<(rows - 1) {
            var line: [Character] = []
            for _ in 0..<columns {
                line.append(chars.randomElement()!)
            }
            sandChars.append(line)
            // Pre-build the trimmed string (drops border column chars at 0 and columns-1).
            sandStrings.append(String(line.dropFirst().dropLast()))
        }
    }

    private func generateDecorations() {
        // Use loaded art if available, otherwise fall back to builtins.
        let loaded = ArtRepository.shared.decorationArt

        let castleArt    = loaded?.castle    ?? DecorationEntity.castleArt
        let castleWidth  = loaded?.castleWidth  ?? DecorationEntity.castleWidth
        let castleHeight = loaded?.castleHeight ?? DecorationEntity.castleHeight
        let rockDesigns  = (loaded?.rocks.isEmpty == false) ? loaded!.rocks : [
            ["  /\\  ", " /  \\ "],
            ["(@@)"],
            [" _/\\_ ", "/    \\"],
            ["(@)"],
            ["  __  ", " /  \\ ", "/    \\"],
        ]
        let shellDesigns: [(String, NSColor)] = (loaded?.shells.isEmpty == false)
            ? loaded!.shells.map { ($0.art, $0.color) }
            : [
                ("@>", ColorPalette.shell),
                ("<@", ColorPalette.shell),
                ("()", ColorPalette.shell),
                ("-*-", ColorPalette.starfish),
                ("*", ColorPalette.starfish),
                ("o", ColorPalette.shell),
            ]

        // Place the large castle
        let castleX: Int
        if columns > castleWidth + 20 {
            castleX = columns - castleWidth - Int.random(in: 3...8)
        } else if columns > castleWidth + 4 {
            castleX = columns - castleWidth - 2
        } else {
            castleX = -1  // too narrow, skip castle
        }

        if castleX > 1 {
            let castleRow = sandRow - castleHeight
            // Castle body in gray
            objects.append(Decoration(
                art: castleArt,
                col: castleX,
                row: castleRow,
                color: ColorPalette.castle
            ))
            // Castle flag top in yellow (first line of art)
            if let flagLine = castleArt.first {
                objects.append(Decoration(
                    art: [flagLine],
                    col: castleX,
                    row: castleRow,
                    color: ColorPalette.castleFlag
                ))
            }
        }

        // Place some rocks (avoid castle area)
        let avoidZones = castleX > 0 ? [castleX] : [Int]()
        let rockPositions = randomPositions(count: 3, minX: 2, maxX: columns - 6,
                                            avoid: avoidZones, avoidRadius: castleWidth + 5)

        for pos in rockPositions {
            let design = rockDesigns.randomElement()!
            let rockRow = sandRow - design.count
            objects.append(Decoration(
                art: design, col: pos, row: rockRow, color: ColorPalette.rock))
        }

        // Place shells and starfish on the sand
        let shellPositions = randomPositions(count: 5, minX: 2, maxX: columns - 4,
                                             avoid: rockPositions + avoidZones, avoidRadius: 10)
        for pos in shellPositions {
            let (design, color) = shellDesigns.randomElement()!
            objects.append(Decoration(
                art: [design], col: pos, row: sandRow - 1, color: color))
        }
    }

    private func randomPositions(count: Int, minX: Int, maxX: Int, avoid: [Int], avoidRadius: Int = 8) -> [Int] {
        guard maxX > minX else { return [] }
        var positions: [Int] = []
        var attempts = 0
        while positions.count < count && attempts < count * 15 {
            let x = Int.random(in: minX...maxX)
            let tooClose = positions.contains(where: { abs($0 - x) < 8 })
                || avoid.contains(where: { abs($0 - x) < avoidRadius })
            if !tooClose {
                positions.append(x)
            }
            attempts += 1
        }
        return positions
    }

    // Pre-built sand row strings (strip border columns once at init).
    private var sandStrings: [String] = []

    func renderSand(into grid: GridRenderer) {
        for (i, s) in sandStrings.enumerated() {
            let row = sandRow + i
            let color = i == 0 ? ColorPalette.sand : ColorPalette.sandDark
            // putString with transparent:false and a single colorIndex lookup
            // per row is cheaper than individual putChar calls.
            grid.putString(s, at: 1, row: row, foreground: color, transparent: false)
        }
    }

    func renderObjects(into grid: GridRenderer) {
        for obj in objects {
            grid.putMultilineArt(obj.art, at: obj.col, row: obj.row, foreground: obj.color)
        }
    }
}
