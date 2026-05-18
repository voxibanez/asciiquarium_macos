import AppKit
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.asciifishtank.screensaver", category: "Scene")

class AquariumScene {
    deinit {
        logger.info("AsciiFishtank: AquariumScene deallocated")
    }

    var fish: [FishEntity] = []
    var bubbles: [BubbleEntity] = []
    var seaweed: [SeaweedEntity] = []
    var decorations: DecorationEntity!
    var waterSurface: WaterSurface!
    var ships: [ShipEntity] = []
    var sharks: [SharkEntity] = []
    var whales: [WhaleEntity] = []
    var monsters: [MonsterEntity] = []
    var splats: [SplatEntity] = []
    var jellyfish: [JellyfishEntity] = []
    var crabs: [CrabEntity] = []
    var treasureChest: TreasureChest!
    var frameCount: Int = 0
    var nextSchoolId: Int = 0

    // Real-time accumulators (seconds) for events that used to key off frameCount % (fps * interval).
    // Using elapsed time makes them FPS-independent.
    private var bubbleAccum: Double = 0
    private var fishBubbleAccum: Double = 0
    private var sharkAccum: Double = 0
    private var whaleAccum: Double = 0
    private var monsterAccum: Double = 0
    private var shipAccum: Double = 0
    private var schoolAccum: Double = 0
    private var jellyfishAccum: Double = 0

    var columns: Int = 0
    var rows: Int = 0
    var sandTop: Int = 0
    var waterRow: Int = 3

    // Configuration
    var config = AquariumConfig()

    func setup(columns: Int, rows: Int, config: AquariumConfig = AquariumConfig()) {
        self.columns = columns
        self.rows = rows
        self.config = config

        // Create decorations (sets up the sand row)
        decorations = DecorationEntity(columns: columns, rows: rows)
        sandTop = decorations.sandRow

        // Create water surface
        waterSurface = WaterSurface(columns: columns)

        // Create treasure chest on the sand floor
        if config.treasureChestEnabled {
            let chestX = Int.random(in: 4...(columns / 3))
            treasureChest = TreasureChest(
                col: chestX,
                row: sandTop - TreasureChest.height
            )
        }

        // Spawn fish - scale count with screen width, using config density
        let fishCount = max(8, columns / config.fishDensity)
        for _ in 0..<fishCount {
            fish.append(spawnSeparatedFish())
        }

        // Spawn an initial school
        let school = FishEntity.spawnSchool(columns: columns, rows: rows, sandTop: sandTop, schoolId: nextSchoolId)
        nextSchoolId += 1
        fish.append(contentsOf: school)

        // Spawn seaweed
        let seaweedCount = max(4, columns / config.seaweedDensity)
        for _ in 0..<seaweedCount {
            seaweed.append(SeaweedEntity.spawnRandom(baseRow: sandTop, columns: columns))
        }

        // Spawn a few initial bubbles
        for _ in 0..<3 {
            var bubble = BubbleEntity.spawnRandom(columns: columns, bottomRow: sandTop)
            bubble.y = Double.random(in: 4.0...Double(sandTop - 1))
            bubbles.append(bubble)
        }

        // Spawn crabs
        for _ in 0..<config.crabCount {
            crabs.append(CrabEntity.spawnRandom(columns: columns, sandRow: sandTop))
        }

        // Spawn initial jellyfish
        if config.jellyfishEnabled {
            jellyfish.append(JellyfishEntity.spawnRandom(columns: columns, sandTop: sandTop))
        }
    }

    func tick(dt: Double) {
        frameCount += 1

        // stepSize is the exact number of character columns every entity advances
        // this tick. Tick frequency is controlled by speedMultiplier (via tickInterval).
        // Together they give: cols/sec = stepSize × (baseTickRate × speedMultiplier).
        let speedMult = Double(config.stepSize)

        // Accumulate time for periodic events
        bubbleAccum    += dt
        fishBubbleAccum += dt
        sharkAccum     += dt
        whaleAccum     += dt
        monsterAccum   += dt
        shipAccum      += dt
        schoolAccum    += dt
        jellyfishAccum += dt

        // === Update water surface ===
        waterSurface.tick()

        // === Update treasure chest ===
        treasureChest?.tick()

        // === Update fish ===
        // Hoist bubble rate computation out of the per-fish loop.
        let bubbleRatePerSec = 1.0 / Double(config.fishBubbleChance)
        let bubbleThreshold = bubbleRatePerSec * dt * AquariumConfig.baseTickRate
        let colsM2 = columns - 2
        let staggered = config.staggeredMovement && config.stepSize > 1
        let stepSize = Double(config.stepSize)
        for i in 0..<fish.count {
            if staggered {
                // Each fish ticks at its own frequency based on its speed property.
                // A higher speed makes the accumulator reach the 1.0 threshold faster.
                fish[i].moveAccumulator += fish[i].speed
                if fish[i].moveAccumulator < 1.0 { continue }
                fish[i].moveAccumulator -= 1.0

                // When it's time to move, jump by exactly the global stepSize.
                // We pass a multiplier that cancels out the fish's internal speed.
                fish[i].tick(columns: columns, rows: rows, sandTop: sandTop, 
                            speedMultiplier: stepSize / fish[i].speed)
            } else {
                fish[i].tick(columns: columns, rows: rows, sandTop: sandTop, speedMultiplier: stepSize)
            }

            // Fish bubble emission: emit at a rate of ~(1/fishBubbleChance) per second
            if Double.random(in: 0..<1) < bubbleThreshold {
                let pos = fish[i].bubblePosition()
                if pos.col > 1 && pos.col < colsM2 && pos.row > 3 {
                    bubbles.append(BubbleEntity.spawnAt(col: pos.col, row: pos.row))
                }
            }
        }
        // === Update sharks ===
        if config.sharksEnabled {
            for i in 0..<sharks.count {
                sharks[i].tick(columns: columns, speedMultiplier: speedMult)
            }
            sharks.removeAll { $0.isDead }

            // Shark eats fish - create splats
            for shark in sharks {
                var eaten: [(Int, Int)] = []
                fish.removeAll { fishEntity in
                    if shark.eats(fish: fishEntity) {
                        let col = Int(fishEntity.x.rounded())
                        eaten.append((col, fishEntity.y))
                        return true
                    }
                    return false
                }
                for (ex, ey) in eaten {
                    splats.append(SplatEntity.spawn(at: ex, fishY: ey))
                }
            }
        }

        // Replenish eaten fish (targetFishCount matches setup; hoist out of loop)
        let targetFishCount = max(8, columns / config.fishDensity)
        while fish.count < targetFishCount {
            var newFish = spawnSeparatedFish()
            if newFish.direction == .right {
                newFish.x = Double(-newFish.design.width - Int.random(in: 5...30))
            } else {
                newFish.x = Double(columns + Int.random(in: 5...30))
            }
            fish.append(newFish)
        }

        // === Update splats ===
        for i in 0..<splats.count { splats[i].tick() }
        splats.removeAll { $0.isDead }

        // === Update whales ===
        if config.whalesEnabled {
            for i in 0..<whales.count {
                whales[i].tick(columns: columns, speedMultiplier: speedMult)
            }
            whales.removeAll { $0.isDead }
        }

        // === Update monsters ===
        if config.monstersEnabled {
            for i in 0..<monsters.count {
                monsters[i].tick(columns: columns, speedMultiplier: speedMult)
            }
            monsters.removeAll { $0.isDead }
        }

        // === Update jellyfish ===
        if config.jellyfishEnabled {
            for i in 0..<jellyfish.count {
                jellyfish[i].tick(columns: columns, rows: rows)
            }
            jellyfish.removeAll { $0.isDead }

            // Respawn jellyfish using time-based probability
            if jellyfish.count < 1 && Double.random(in: 0..<1) < dt / 10.0 {
                jellyfish.append(JellyfishEntity.spawnRandom(columns: columns, sandTop: sandTop))
            } else if jellyfish.count < config.maxJellyfish && Double.random(in: 0..<1) < dt / 20.0 {
                jellyfish.append(JellyfishEntity.spawnRandom(columns: columns, sandTop: sandTop))
            }
        }

        // === Update crabs ===
        for i in 0..<crabs.count { crabs[i].tick(columns: columns, speedMultiplier: speedMult) }

        // === Spawn rare events (real-time accumulators) ===

        if config.sharksEnabled && sharks.isEmpty
            && sharkAccum >= Double(config.sharkSpawnInterval) {
            sharkAccum = 0
            if Int.random(in: 0..<3) == 0 {
                sharks.append(SharkEntity.spawnRandom(columns: columns, rows: rows, sandTop: sandTop))
            }
        }

        if config.whalesEnabled && whales.isEmpty && monsters.isEmpty && sharks.isEmpty
            && whaleAccum >= Double(config.whaleSpawnInterval) {
            whaleAccum = 0
            if Int.random(in: 0..<3) == 0 {
                whales.append(WhaleEntity.spawnRandom(columns: columns, rows: rows, sandTop: sandTop))
            }
        }

        if config.monstersEnabled && monsters.isEmpty && whales.isEmpty && sharks.isEmpty
            && monsterAccum >= Double(config.monsterSpawnInterval) {
            monsterAccum = 0
            if Int.random(in: 0..<4) == 0 {
                monsters.append(MonsterEntity.spawnRandom(columns: columns, rows: rows, sandTop: sandTop))
            }
        }

        if config.shipsEnabled && ships.isEmpty
            && shipAccum >= Double(config.shipSpawnInterval) {
            shipAccum = 0
            if Int.random(in: 0..<2) == 0 {
                ships.append(ShipEntity.spawnRandom(columns: columns))
            }
        }

        if schoolAccum >= Double(config.schoolSpawnInterval) {
            schoolAccum = 0
            if Int.random(in: 0..<2) == 0 {
                let school = FishEntity.spawnSchool(
                    columns: columns, rows: rows, sandTop: sandTop, schoolId: nextSchoolId)
                nextSchoolId += 1
                fish.append(contentsOf: school)
            }
        }

        // === Update ships ===
        if config.shipsEnabled {
            for i in 0..<ships.count {
                ships[i].tick(columns: columns, speedMultiplier: speedMult)
            }
            ships.removeAll { $0.isDead }
        }

        // === Update bubbles ===
        for i in 0..<bubbles.count {
            bubbles[i].tick(columns: columns, bottomRow: sandTop, speedMultiplier: speedMult)
        }
        bubbles.removeAll { $0.isDead }

        // Spawn ambient bubbles: bubbleSpawnInterval is seconds between spawns
        let bubbleIntervalSec = Double(config.bubbleSpawnInterval) / AquariumConfig.baseTickRate
        if bubbleAccum >= bubbleIntervalSec {
            bubbleAccum = 0
            bubbles.append(BubbleEntity.spawnRandom(columns: columns, bottomRow: sandTop))
        }

        // === Update seaweed ===
        for i in 0..<seaweed.count { seaweed[i].tick() }
    }

    func render(into grid: GridRenderer) {
        grid.clear()

        // 1. Water surface
        waterSurface.render(into: grid)

        // 2. Sand floor
        decorations.renderSand(into: grid)

        // 3. Seaweed (behind everything underwater)
        for i in seaweed.indices { seaweed[i].render(into: grid) }

        // 4. Treasure chest
        treasureChest?.render(into: grid)

        // 5. Decorations (rocks, castle, shells)
        decorations.renderObjects(into: grid)

        // 6. Crabs (on sand, in front of decorations)
        for i in crabs.indices { crabs[i].render(into: grid) }

        // 7. Jellyfish (behind fish)
        for i in jellyfish.indices { jellyfish[i].render(into: grid) }

        // 8. Fish
        for i in fish.indices { fish[i].render(into: grid) }

        // 9. Whales
        for i in whales.indices { whales[i].render(into: grid) }

        // 10. Monsters
        for i in monsters.indices { monsters[i].render(into: grid) }

        // 11. Sharks (in front of fish)
        for i in sharks.indices { sharks[i].render(into: grid) }

        // 12. Splats (on top of everything underwater)
        for i in splats.indices { splats[i].render(into: grid) }

        // 13. Bubbles (front-most underwater layer)
        for i in bubbles.indices { bubbles[i].render(into: grid) }

        // 14. Ships (on top of water, above everything)
        for i in ships.indices { ships[i].render(into: grid, waterRow: waterRow) }

        // 15. Border (draw last so it covers entities entering from off-screen)
        if config.showBorder {
            drawBorder(into: grid)
        }
    }

    private func drawBorder(into grid: GridRenderer) {
        let color = ColorPalette.border

        for col in 0..<columns {
            grid.putChar("=", at: col, row: 0, foreground: color, bold: true)
            grid.putChar("=", at: col, row: rows - 1, foreground: color, bold: true)
        }

        for row in 0..<rows {
            grid.putChar("|", at: 0, row: row, foreground: color)
            grid.putChar("|", at: columns - 1, row: row, foreground: color)
        }

        grid.putChar("+", at: 0, row: 0, foreground: color, bold: true)
        grid.putChar("+", at: columns - 1, row: 0, foreground: color, bold: true)
        grid.putChar("+", at: 0, row: rows - 1, foreground: color, bold: true)
        grid.putChar("+", at: columns - 1, row: rows - 1, foreground: color, bold: true)
    }

    private func spawnSeparatedFish() -> FishEntity {
        var candidate = FishEntity.spawnRandom(columns: columns, rows: rows, sandTop: sandTop)
        for _ in 0..<12 {
            guard fish.contains(where: { fishNearlyFullyOverlap(candidate, $0) }) else {
                return candidate
            }
            candidate = FishEntity.spawnRandom(columns: columns, rows: rows, sandTop: sandTop)
        }
        return candidate
    }

    private func fishNearlyFullyOverlap(_ lhs: FishEntity, _ rhs: FishEntity) -> Bool {
        let lhsLeft = Int(lhs.x.rounded())
        let lhsRight = lhsLeft + lhs.design.width
        let rhsLeft = Int(rhs.x.rounded())
        let rhsRight = rhsLeft + rhs.design.width

        let lhsTop = lhs.y
        let lhsBottom = lhs.y + lhs.design.height
        let rhsTop = rhs.y
        let rhsBottom = rhs.y + rhs.design.height

        let overlapWidth = min(lhsRight, rhsRight) - max(lhsLeft, rhsLeft)
        let overlapHeight = min(lhsBottom, rhsBottom) - max(lhsTop, rhsTop)
        guard overlapWidth > 0, overlapHeight > 0 else { return false }

        let lhsArea = lhs.design.width * lhs.design.height
        let rhsArea = rhs.design.width * rhs.design.height
        let smallerArea = max(1, min(lhsArea, rhsArea))
        return Double(overlapWidth * overlapHeight) / Double(smallerArea) > 0.65
    }

}
