import AppKit
import Foundation

struct MonsterEntity {
    var x: Double
    var direction: Direction
    var speed: Double
    var isDead: Bool = false
    var frameCounter: Int = 0
    var animFrame: Int = 0

    // Runtime art from ArtRepository (falls back to builtins if no TXT file).
    static var rightFrames: [[String]] { ArtRepository.shared.monsterRightFrames }
    static var leftFrames:  [[String]] { ArtRepository.shared.monsterLeftFrames }
    static var width:       Int        { ArtRepository.shared.monsterWidth }
    static var height:      Int        { ArtRepository.shared.monsterHeight }

    // Builtin fallbacks
    static let builtinRightFrames: [[String]] = [
        [
            "         _                  _        _a_a",
            "       _{.`=`.}_          _{.`=`.}_ {/ ''\\_ ",
            " _    {.'  _  '.}       {.'  _  '.}{|  ._oo)",
            "{ \\  {/  .'_'.  \\}     {/  .'_'.  \\{/  |  ",
        ],
        [
            "                  _                  _a_a",
            "  _          _{.`=`.}_          _  {/ ''\\_ ",
            " { \\       {.'  _  '.}       {.`'`.}{|  ._oo)",
            "  \\ \\     {/  .'_'.  \\}     {/ .-. \\{/  |  ",
        ],
    ]
    static let builtinLeftFrames: [[String]] = [
        [
            "   a_a_        _                  _        ",
            " _/'' \\}  _{.`=`.}_          _{.`=`.}_    ",
            "(oo_.  |}{.'  _  '.}       {.'  _  '.}   _",
            "    |  \\{/  .'_'.  \\}     {/  .'_'.  \\}/ }",
        ],
        [
            "   a_a_                  _                 ",
            " _/'' \\}  _          _{.`=`.}_             ",
            "(oo_.  |}{.`'`.}   {.'  _  '.}          / }",
            "    |  \\{/ .-. \\}{/  .'_'.  \\}       / /  ",
        ],
    ]
    static let builtinWidth  = 50
    static let builtinHeight = 4

    mutating func tick(columns: Int, speedMultiplier: Double = 1.0) {
        x += speed * direction.sign * speedMultiplier
        frameCounter += 1

        // Undulation animation - swap frames every 12 ticks
        if frameCounter % 12 == 0 {
            let frames = MonsterEntity.rightFrames
            animFrame = (animFrame + 1) % max(1, frames.count)
        }

        let w = Double(MonsterEntity.width)
        if direction == .right && x > Double(columns) + 5 {
            isDead = true
        } else if direction == .left && x < -w - 5 {
            isDead = true
        }
    }

    func render(into grid: GridRenderer) {
        let frames = direction == .right ? MonsterEntity.rightFrames : MonsterEntity.leftFrames
        let art = frames[animFrame % max(1, frames.count)]
        let (col, offset) = grid.colAndOffset(for: x)
        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: y + i, foreground: ColorPalette.monster, xOffset: offset)
        }
    }

    var y: Int  // vertical position

    static func spawnRandom(columns: Int, rows: Int, sandTop: Int) -> MonsterEntity {
        let direction: Direction = Bool.random() ? .left : .right
        let x: Double = direction == .right ? Double(-MonsterEntity.width - 5) : Double(columns + 5)
        let speed = Double.random(in: 0.2...0.35)
        let minY = 5
        let maxY = max(minY, sandTop - MonsterEntity.height - 2)
        let y = Int.random(in: minY...maxY)

        return MonsterEntity(x: x, direction: direction, speed: speed, y: y)
    }
}
