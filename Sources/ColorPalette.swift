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
