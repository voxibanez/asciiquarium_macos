import Foundation
import ScreenSaver

/// Centralized configuration for all adjustable aquarium parameters.
/// Persists to UserDefaults via ScreenSaverDefaults.
struct AquariumConfig: Codable {
    // Bundle identifier for ScreenSaverDefaults
    static let bundleId = "com.asciifishtank.screensaver"
    static let configKey = "config"

    // --- Bubble Settings ---
    var bubbleSpawnInterval: Int = 28
    var fishBubbleChance: Int = 200

    // --- Fish Settings ---
    var fishDensity: Int = 15
    var schoolSpawnInterval: Int = 60

    // --- Creature Spawn Intervals (seconds) ---
    var sharkSpawnInterval: Int = 45
    var whaleSpawnInterval: Int = 40
    var monsterSpawnInterval: Int = 90
    var shipSpawnInterval: Int = 30

    // --- Speed ---
    var speedMultiplier: Double = 1.0
    var stepSize: Int = 1
    static let baseTickRate: Double = 15.0

    var tickInterval: Double { Double(stepSize) / (AquariumConfig.baseTickRate * speedMultiplier) }

    // --- Creature Counts ---
    var crabCount: Int = 2
    var seaweedDensity: Int = 20
    var maxJellyfish: Int = 2

    // --- Display ---
    var fontSize: Double = 14.0
    var showBorder: Bool = true

    // --- Toggle Features ---
    var sharksEnabled: Bool = true
    var whalesEnabled: Bool = true
    var monstersEnabled: Bool = true
    var shipsEnabled: Bool = true
    var jellyfishEnabled: Bool = true
    var treasureChestEnabled: Bool = true

    // --- Movement ---
    var staggeredMovement: Bool = false

    // MARK: - Persistence

    static func load() -> AquariumConfig {
        guard let defaults = ScreenSaverDefaults(forModuleWithName: bundleId),
              let data = defaults.data(forKey: configKey) else {
            return AquariumConfig()
        }

        do {
            let decoder = PropertyListDecoder()
            return try decoder.decode(AquariumConfig.self, from: data)
        } catch {
            print("Failed to decode config: \(error)")
            return AquariumConfig()
        }
    }

    func save() {
        guard let defaults = ScreenSaverDefaults(forModuleWithName: AquariumConfig.bundleId) else { return }
        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(self)
            defaults.set(data, forKey: AquariumConfig.configKey)
            defaults.synchronize()
        } catch {
            print("Failed to encode config: \(error)")
        }
    }

    static func resetToDefaults() {
        guard let defaults = ScreenSaverDefaults(forModuleWithName: bundleId) else { return }
        defaults.removeObject(forKey: configKey)
        defaults.synchronize()
    }
}

