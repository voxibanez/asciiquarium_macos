import AppKit

struct SplatEntity {
    var col: Int
    var row: Int
    var frameCounter: Int = 0
    var isDead: Bool = false

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var frames: [[String]] { ArtRepository.shared.splatFrames }

    // Builtin fallbacks
    static let builtinFrames: [[String]] = [
        [
            "  .  ",
            " *** ",
            "  '  ",
        ],
        [
            " \",*;`",
            " \"*,**",
            " *\"'~'",
        ],
        [
            "  , , ",
            " \" \",\"'",
            " *\" *'\"",
            "  \" ; .",
        ],
        [
            "* ' , ' `",
            "' ` * . '",
            " ' `' \",'",
            "* ' \" * .",
            "\" * ', ' ",
        ],
    ]

    static let splatColor = NSColor(calibratedRed: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)

    mutating func tick() {
        frameCounter += 1
        if frameCounter > 20 {
            isDead = true
        }
    }

    func render(into grid: GridRenderer) {
        let allFrames = SplatEntity.frames
        // Cycle through frames
        let frameIdx = min(frameCounter / 5, allFrames.count - 1)
        let art = allFrames[frameIdx]

        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: row + i, foreground: SplatEntity.splatColor)
        }
    }

    static func spawn(at fishX: Int, fishY: Int) -> SplatEntity {
        return SplatEntity(col: fishX, row: fishY)
    }
}
