import AppKit

enum Direction {
    case left, right

    var sign: Double { self == .right ? 1.0 : -1.0 }
}

struct FishDesign {
    let rightArt: [String]
    let leftArt: [String]
    let width: Int
    let height: Int

    /// Designs loaded from Art/Fish/ TXT files at runtime (populated by ArtRepository).
    static var allDesigns: [FishDesign] { ArtRepository.shared.fishDesigns }

    /// Builtin fallback designs — used when no TXT files are found.
    static let builtinDesigns: [FishDesign] = [
        // 1. Classic small
        FishDesign(
            rightArt: [
                "  __",
                "><_'>",
                "  ' ",
            ],
            leftArt: [
                " __  ",
                "<'_><",
                "  `  ",
            ],
            width: 5, height: 3
        ),
        // 2. Simple with tail
        FishDesign(
            rightArt: [
                "  ,\\",
                ">=('>",
                "  '/",
            ],
            leftArt: [
                " /,  ",
                "<')=<",
                " \\'  ",
            ],
            width: 5, height: 3
        ),
        // 3. Round fish
        FishDesign(
            rightArt: [
                "  __",
                "\\/ o\\",
                "/\\__/",
            ],
            leftArt: [
                "__   ",
                "/o \\/",
                "\\__/\\",
            ],
            width: 5, height: 3
        ),
        // 4. Dotted tail
        FishDesign(
            rightArt: [
                "   ..\\ ",
                ">='   ('>",
                "  '''/'' ",
            ],
            leftArt: [
                "  ,/..   ",
                "<')   `=<",
                " ``\\```  ",
            ],
            width: 9, height: 3
        ),
        // 5. Finned fish
        FishDesign(
            rightArt: [
                "   \\  ",
                "  / \\ ",
                ">=_('>",
                "  \\_/ ",
                "   /  ",
            ],
            leftArt: [
                "  /   ",
                " / \\  ",
                "<')_=<",
                " \\_/  ",
                "  \\   ",
            ],
            width: 6, height: 5
        ),
        // 6. Fancy tail fish
        FishDesign(
            rightArt: [
                "       \\    ",
                "     ...\\...",
                "\\  /'       \\",
                " >=     (  ' >",
                "/  \\      / / ",
                "    `\"'\"'/''  ",
            ],
            leftArt: [
                "      /       ",
                "  ,../...     ",
                " /       '\\  /",
                "< '  )     =< ",
                " \\ \\      /  \\",
                "  `'\\'\"`'     ",
            ],
            width: 15, height: 6
        ),
        // 7. Spiny fish
        FishDesign(
            rightArt: [
                "    \\  ",
                "\\ /--\\ ",
                ">=  (o>",
                "/ \\__/ ",
                "    /  ",
            ],
            leftArt: [
                "  /    ",
                " /--\\ /",
                "<o)  =<",
                " \\__/ \\",
                "  \\    ",
            ],
            width: 7, height: 5
        ),
        // 8. Detailed big fish
        FishDesign(
            rightArt: [
                "       ,--,_   ",
                "__    _\\.---'-.",
                "\\ '.-\"     // o\\",
                "/_.'-._    \\\\  /",
                "       `\"--(/\"`",
            ],
            leftArt: [
                "    _,--,      ",
                ".-'---./_    __",
                "/o \\\\     \"-.' /",
                "\\  //    _.-'._\\",
                " `\"\\)--\"`      ",
            ],
            width: 16, height: 5
        ),
        // 9. Striped fish
        FishDesign(
            rightArt: [
                "       \\:.",
                "\\;,   ,;\\\\\\,,",
                "  \\\\\\;;:::::::o",
                "  ///;;::::::::<",
                " /;` ``/////``",
            ],
            leftArt: [
                "      .:/      ",
                "   ,,///;,   ,;/",
                " o:::::::;;/// ",
                ">::::::::;;\\\\\\\\",
                "  ''\\\\\\\\'' ';/ ",
            ],
            width: 16, height: 5
        ),
        // 10. Curly fish
        FishDesign(
            rightArt: [
                "     ,  ",
                "     \\}\\",
                "\\  .'  `\\",
                "}}<   ( 6>",
                "/  `,  .'",
                "     \\}/",
                "     '  ",
            ],
            leftArt: [
                "    ,   ",
                "   /{\\  ",
                " /'  `. /",
                "<6 )   >/{",
                " `.  ,'  \\",
                "   \\{/   ",
                "    `    ",
            ],
            width: 10, height: 7
        ),
    ]
}  // end FishDesign

struct FishEntity {
    var x: Double
    var y: Int
    var speed: Double
    var direction: Direction
    var design: FishDesign
    var color: NSColor
    var frameCounter: Int = 0
    var alive: Bool = true
    var schoolId: Int = -1  // -1 = solo, >= 0 = belongs to a school
    /// Phase offset for staggered movement mode. When staggeredMovement is enabled,
    /// this fish only ticks when (globalFrameCount % stepSize) == tickOffset.
    var tickOffset: Int = 0
    // Called by AquariumScene with configurable chance
    func wantsBubble(chance: Int) -> Bool {
        return Int.random(in: 0..<chance) == 0
    }

    mutating func tick(columns: Int, rows: Int, sandTop: Int, speedMultiplier: Double = 1.0) {
        x += speed * direction.sign * speedMultiplier
        frameCounter += 1

        // Gentle vertical drift (rare ~0.83% chance per tick)
        if Double.random(in: 0..<1) < 0.00833 {
            let r = Double.random(in: 0..<1)
            let delta = r < 0.333 ? -1 : (r < 0.667 ? 0 : 1)
            let newY = y + delta
            let minY = 5
            let maxY = sandTop - design.height - 1
            if newY >= minY && newY <= maxY {
                y = newY
            }
        }

        // Wrap around
        let fishWidth = Double(design.width)
        if direction == .right && x > Double(columns) + 2 {
            x = -fishWidth - 1
            randomizeDepth(columns: columns, sandTop: sandTop)
        } else if direction == .left && x < -fishWidth - 2 {
            x = Double(columns) + 1
            randomizeDepth(columns: columns, sandTop: sandTop)
        }
    }

    // Returns the position where a bubble should spawn (near the mouth)
    func bubblePosition() -> (col: Int, row: Int) {
        let col = Int(x.rounded())
        if direction == .right {
            return (col + design.width, y + design.height / 2)
        } else {
            return (col - 1, y + design.height / 2)
        }
    }

    private mutating func randomizeDepth(columns: Int, sandTop: Int) {
        let minY = 5
        let maxY = max(minY, sandTop - design.height - 1)
        y = Int.random(in: minY...maxY)
        speed = Double.random(in: 0.08...0.4)
    }

    func render(into grid: GridRenderer) {
        let art = direction == .right ? design.rightArt : design.leftArt
        let (col, offset) = grid.colAndOffset(for: x)
        for (i, line) in art.enumerated() {
            grid.putString(line, at: col, row: y + i, foreground: color, xOffset: offset)
        }
    }

    static func spawnRandom(columns: Int, rows: Int, sandTop: Int, stepSize: Int = 1) -> FishEntity {
        let design = FishDesign.allDesigns.randomElement()!
        let direction: Direction = Bool.random() ? .left : .right
        let minY = 5
        let maxY = max(minY, sandTop - design.height - 1)
        let y = Int.random(in: minY...maxY)
        let x = Double.random(in: 0.0...Double(columns))
        let speed = Double.random(in: 0.08...0.4)
        let color = ColorPalette.fishColors.randomElement()!
        let offset = stepSize > 1 ? Int.random(in: 0..<stepSize) : 0

        return FishEntity(
            x: x, y: y, speed: speed, direction: direction,
            design: design, color: color, tickOffset: offset)
    }

    // Create a school of small fish that swim together
    static func spawnSchool(columns: Int, rows: Int, sandTop: Int, schoolId: Int, stepSize: Int = 1) -> [FishEntity] {
        let smallDesigns = Array(FishDesign.allDesigns.prefix(4))
        let design = smallDesigns.randomElement()!
        let direction: Direction = Bool.random() ? .left : .right
        let color = ColorPalette.fishColors.randomElement()!
        let baseSpeed = Double.random(in: 0.12...0.3)
        let minY = 6
        let maxY = max(minY, sandTop - 10)
        let baseY = Int.random(in: minY...maxY)
        let baseX: Double = direction == .right
            ? Double(-design.width - Int.random(in: 10...40))
            : Double(columns + Int.random(in: 10...40))

        // All fish in a school share the same tick offset so they move as a unit
        let sharedOffset = stepSize > 1 ? Int.random(in: 0..<stepSize) : 0

        let count = Int.random(in: 3...6)
        var school: [FishEntity] = []

        for i in 0..<count {
            let offsetX = Double(i % 3) * Double.random(in: 4...8) * (direction == .right ? -1 : 1)
            let offsetY = (i / 3) * Int.random(in: 2...3)
            let speedVariation = Double.random(in: -0.02...0.02)

            var fish = FishEntity(
                x: baseX + offsetX,
                y: baseY + offsetY,
                speed: baseSpeed + speedVariation,
                direction: direction,
                design: design,
                color: color,
                schoolId: schoolId,
                tickOffset: sharedOffset
            )
            fish.alive = true
            school.append(fish)
        }

        return school
    }
}
