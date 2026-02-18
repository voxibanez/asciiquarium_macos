import Foundation
import ScreenSaver

/// Centralized configuration for all adjustable aquarium parameters.
/// Persists to UserDefaults via ScreenSaverDefaults.
struct AquariumConfig {
    // Bundle identifier for ScreenSaverDefaults
    static let bundleId = "com.asciifishtank.screensaver"

    // --- Bubble Settings ---
    var bubbleSpawnInterval: Int = 28       // frames between ambient bubble spawns (lower = more)
    var fishBubbleChance: Int = 200         // 1-in-N chance per frame per fish (lower = more)

    // --- Fish Settings ---
    var fishDensity: Int = 15               // columns / fishDensity = fish count (lower = more fish)
    var schoolSpawnInterval: Int = 60       // seconds between school spawns

    // --- Creature Spawn Intervals (seconds) ---
    var sharkSpawnInterval: Int = 45
    var whaleSpawnInterval: Int = 40
    var monsterSpawnInterval: Int = 90
    var shipSpawnInterval: Int = 30

    // --- Speed ---
    // Controls how frequently the simulation ticks (ticks/sec = baseTickRate × speedMultiplier).
    var speedMultiplier: Double = 1.0       // tick rate scale (0.25 – 3.0)

    // --- Step Size ---
    // How many character columns each entity advances per tick.
    // 1 = one char per tick (authentic terminal motion, smoothest pacing).
    // Higher values = coarser jumps; gives a different retro feel.
    var stepSize: Int = 1                   // columns per tick (1 – 8)

    // Base tick rate before speedMultiplier scaling.
    static let baseTickRate: Double = 15.0  // ticks per second at speedMultiplier = 1.0

    /// Wall-clock seconds between simulation ticks at the current speed.
    /// stepSize scales the interval inversely so that cols/sec = baseTickRate × speedMultiplier
    /// regardless of stepSize. Bigger steps → fewer ticks → same linear velocity.
    var tickInterval: Double { Double(stepSize) / (AquariumConfig.baseTickRate * speedMultiplier) }

    // --- Creature Counts ---
    var crabCount: Int = 2
    var seaweedDensity: Int = 20            // columns / seaweedDensity = seaweed count (lower = more)
    var maxJellyfish: Int = 2

    // --- Display ---
    var fontSize: Double = 14.0            // character size (8 - 24)
    var showBorder: Bool = true

    // --- Toggle Features ---
    var sharksEnabled: Bool = true
    var whalesEnabled: Bool = true
    var monstersEnabled: Bool = true
    var shipsEnabled: Bool = true
    var jellyfishEnabled: Bool = true
    var treasureChestEnabled: Bool = true

    // --- Movement ---
    /// When true, each fish gets a random tick-phase offset so they don't all
    /// move on the same global tick — creates a more organic, dynamic look.
    var staggeredMovement: Bool = false

    // MARK: - Persistence

    static func load() -> AquariumConfig {
        guard let defaults = ScreenSaverDefaults(forModuleWithName: bundleId) else {
            return AquariumConfig()
        }

        // If nothing has been saved yet, just return defaults
        if defaults.object(forKey: "bubbleSpawnInterval") == nil {
            return AquariumConfig()
        }

        var config = AquariumConfig()
        config.bubbleSpawnInterval = max(5, defaults.integer(forKey: "bubbleSpawnInterval"))
        config.fishBubbleChance = max(10, defaults.integer(forKey: "fishBubbleChance"))
        config.fishDensity = max(3, defaults.integer(forKey: "fishDensity"))
        config.schoolSpawnInterval = max(10, defaults.integer(forKey: "schoolSpawnInterval"))
        config.sharkSpawnInterval = max(10, defaults.integer(forKey: "sharkSpawnInterval"))
        config.whaleSpawnInterval = max(10, defaults.integer(forKey: "whaleSpawnInterval"))
        config.monsterSpawnInterval = max(20, defaults.integer(forKey: "monsterSpawnInterval"))
        config.shipSpawnInterval = max(10, defaults.integer(forKey: "shipSpawnInterval"))

        let speed = defaults.double(forKey: "speedMultiplier")
        config.speedMultiplier = speed > 0 ? max(0.25, min(3.0, speed)) : 1.0

        let stepVal = defaults.integer(forKey: "stepSize")
        config.stepSize = stepVal > 0 ? max(1, min(8, stepVal)) : 1

        config.crabCount = max(0, min(6, defaults.integer(forKey: "crabCount")))
        config.seaweedDensity = max(5, defaults.integer(forKey: "seaweedDensity"))
        config.maxJellyfish = max(0, min(5, defaults.integer(forKey: "maxJellyfish")))

        let fontSizeVal = defaults.double(forKey: "fontSize")
        config.fontSize = fontSizeVal > 0 ? max(8.0, min(24.0, fontSizeVal)) : 14.0

        config.showBorder = defaults.object(forKey: "showBorder") == nil || defaults.bool(forKey: "showBorder")

        // For booleans, check if the key exists before reading (bool defaults to false for missing keys)
        config.sharksEnabled = defaults.object(forKey: "sharksEnabled") == nil || defaults.bool(forKey: "sharksEnabled")
        config.whalesEnabled = defaults.object(forKey: "whalesEnabled") == nil || defaults.bool(forKey: "whalesEnabled")
        config.monstersEnabled = defaults.object(forKey: "monstersEnabled") == nil || defaults.bool(forKey: "monstersEnabled")
        config.shipsEnabled = defaults.object(forKey: "shipsEnabled") == nil || defaults.bool(forKey: "shipsEnabled")
        config.jellyfishEnabled = defaults.object(forKey: "jellyfishEnabled") == nil || defaults.bool(forKey: "jellyfishEnabled")
        config.treasureChestEnabled = defaults.object(forKey: "treasureChestEnabled") == nil || defaults.bool(forKey: "treasureChestEnabled")
        config.staggeredMovement = defaults.object(forKey: "staggeredMovement") != nil && defaults.bool(forKey: "staggeredMovement")
        return config
    }

    func save() {
        guard let defaults = ScreenSaverDefaults(forModuleWithName: AquariumConfig.bundleId) else { return }
        defaults.set(bubbleSpawnInterval, forKey: "bubbleSpawnInterval")
        defaults.set(fishBubbleChance, forKey: "fishBubbleChance")
        defaults.set(fishDensity, forKey: "fishDensity")
        defaults.set(schoolSpawnInterval, forKey: "schoolSpawnInterval")
        defaults.set(sharkSpawnInterval, forKey: "sharkSpawnInterval")
        defaults.set(whaleSpawnInterval, forKey: "whaleSpawnInterval")
        defaults.set(monsterSpawnInterval, forKey: "monsterSpawnInterval")
        defaults.set(shipSpawnInterval, forKey: "shipSpawnInterval")
        defaults.set(speedMultiplier, forKey: "speedMultiplier")
        defaults.set(stepSize, forKey: "stepSize")
        defaults.set(crabCount, forKey: "crabCount")
        defaults.set(seaweedDensity, forKey: "seaweedDensity")
        defaults.set(maxJellyfish, forKey: "maxJellyfish")
        defaults.set(sharksEnabled, forKey: "sharksEnabled")
        defaults.set(whalesEnabled, forKey: "whalesEnabled")
        defaults.set(monstersEnabled, forKey: "monstersEnabled")
        defaults.set(shipsEnabled, forKey: "shipsEnabled")
        defaults.set(jellyfishEnabled, forKey: "jellyfishEnabled")
        defaults.set(treasureChestEnabled, forKey: "treasureChestEnabled")
        defaults.set(staggeredMovement, forKey: "staggeredMovement")
        defaults.set(fontSize, forKey: "fontSize")
        defaults.set(showBorder, forKey: "showBorder")
        defaults.synchronize()
    }

    static func resetToDefaults() {
        guard let defaults = ScreenSaverDefaults(forModuleWithName: bundleId) else { return }
        let keys = ["bubbleSpawnInterval", "fishBubbleChance", "fishDensity", "schoolSpawnInterval",
                     "sharkSpawnInterval", "whaleSpawnInterval", "monsterSpawnInterval", "shipSpawnInterval",
                     "speedMultiplier", "stepSize", "crabCount", "seaweedDensity", "maxJellyfish",
                     "sharksEnabled", "whalesEnabled", "monstersEnabled", "shipsEnabled",
                     "jellyfishEnabled", "treasureChestEnabled", "staggeredMovement", "fontSize", "showBorder"]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }
}
