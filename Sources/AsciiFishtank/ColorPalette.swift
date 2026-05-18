// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit

struct ColorPalette {
    // Background
    static let background = NSColor.black

    // Border
    static let border = NSColor(calibratedRed: 0.3, green: 0.4, blue: 0.9, alpha: 1.0)

    // Sand
    static let sand = NSColor(calibratedRed: 0.8, green: 0.7, blue: 0.3, alpha: 1.0)
    static let sandDark = NSColor(calibratedRed: 0.6, green: 0.5, blue: 0.2, alpha: 1.0)

    // Fish
    static let fishColors: [NSColor] = [
        NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),  // orange
        NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),  // yellow
        NSColor(calibratedRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0),  // cyan
        NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),  // red
        NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.7, alpha: 1.0),  // pink
        NSColor(calibratedRed: 0.5, green: 1.0, blue: 0.5, alpha: 1.0),  // light green
        NSColor(calibratedRed: 0.6, green: 0.6, blue: 1.0, alpha: 1.0),  // lavender
        NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),  // gold
        .white,
        NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),  // dark orange
    ]

    static let asciiquariumFishColors: [NSColor] = [
        NSColor(calibratedRed: 0.0, green: 0.55, blue: 0.55, alpha: 1.0),  // c
        NSColor(calibratedRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0),    // C
        NSColor(calibratedRed: 0.65, green: 0.0, blue: 0.0, alpha: 1.0),   // r
        NSColor(calibratedRed: 1.0, green: 0.2, blue: 0.2, alpha: 1.0),    // R
        NSColor(calibratedRed: 0.7, green: 0.55, blue: 0.0, alpha: 1.0),   // y
        NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.0, alpha: 1.0),    // Y
        NSColor(calibratedRed: 0.0, green: 0.15, blue: 0.75, alpha: 1.0),  // b
        NSColor(calibratedRed: 0.25, green: 0.45, blue: 1.0, alpha: 1.0),  // B
        NSColor(calibratedRed: 0.0, green: 0.55, blue: 0.0, alpha: 1.0),   // g
        NSColor(calibratedRed: 0.2, green: 1.0, blue: 0.2, alpha: 1.0),    // G
        NSColor(calibratedRed: 0.65, green: 0.0, blue: 0.65, alpha: 1.0),  // m
    ]

    static func randomFishPartColors() -> [Character: NSColor] {
        var colors: [Character: NSColor] = ["4": .white]
        for digit in "12356789" {
            colors[digit] = asciiquariumFishColors.randomElement()!
        }
        return colors
    }

    // Seaweed
    static let seaweedColors: [NSColor] = [
        NSColor(calibratedRed: 0.0, green: 0.8, blue: 0.0, alpha: 1.0),
        NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.0, alpha: 1.0),
        NSColor(calibratedRed: 0.4, green: 0.8, blue: 0.0, alpha: 1.0),
        NSColor(calibratedRed: 0.0, green: 0.7, blue: 0.3, alpha: 1.0),
    ]

    // Bubbles
    static let bubble = NSColor(calibratedRed: 0.5, green: 0.7, blue: 1.0, alpha: 0.9)

    // Decorations
    static let rock = NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    static let castle = NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    static let castleFlag = NSColor.yellow
    static let shell = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
    static let starfish = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)

    // Water surface
    static let waterSurface = NSColor(calibratedRed: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)
    static let waterSurfaceLight = NSColor(calibratedRed: 0.5, green: 0.7, blue: 1.0, alpha: 1.0)

    // Ship
    static let ship = NSColor(calibratedRed: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
    static let shipSail = NSColor.white

    // Shark
    static let shark = NSColor(calibratedRed: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)

    // Whale
    static let whale = NSColor(calibratedRed: 0.4, green: 0.5, blue: 0.6, alpha: 1.0)

    // Monster (Nessie)
    static let monster = NSColor(calibratedRed: 0.3, green: 0.7, blue: 0.3, alpha: 1.0)
}
