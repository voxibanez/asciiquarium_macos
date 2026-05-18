// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import SwiftUI
import Observation

@MainActor
@Observable
class SettingsViewModel {
    var config: AquariumConfig

    init() {
        self.config = AquariumConfig.load()
    }

    func save() {
        config.save()
    }

    func reset() {
        AquariumConfig.resetToDefaults()
        config = AquariumConfig()
    }
}

@MainActor
struct AquariumSettingsView: View {
    var viewModel: SettingsViewModel
    var onOK: () -> Void
    var onCancel: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            header
            
            Form {
                Section("Display") {
                    Slider(value: $viewModel.config.fontSize, in: 8...24, step: 0.5) {
                        Text("Font Size: \(viewModel.config.fontSize, specifier: "%.1f") pt")
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.config.stepSize) },
                        set: { viewModel.config.stepSize = Int($0) }
                    ), in: 1...8, step: 1) {
                        Text("Step Size: \(viewModel.config.stepSize) col")
                    }
                    Toggle("Show Border Frame", isOn: $viewModel.config.showBorder)
                }

                Section("Animation") {
                    Slider(value: $viewModel.config.speedMultiplier, in: 0.25...3.0, step: 0.05) {
                        Text("Overall Speed: \(Int(viewModel.config.speedMultiplier * 100))%")
                    }
                    Toggle("Staggered Movement", isOn: $viewModel.config.staggeredMovement)
                }

                Section("Fish & Schools") {
                    Slider(value: Binding(
                        get: { Double(viewModel.config.fishDensity) },
                        set: { viewModel.config.fishDensity = Int($0) }
                    ), in: 3...40, step: 1) {
                        Text("Fish Density")
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.config.schoolSpawnInterval) },
                        set: { viewModel.config.schoolSpawnInterval = Int($0) }
                    ), in: 10...180, step: 1) {
                        Text("School Interval: \(viewModel.config.schoolSpawnInterval)s")
                    }
                }

                Section("Bubbles") {
                    Slider(value: Binding(
                        get: { Double(viewModel.config.bubbleSpawnInterval) },
                        set: { viewModel.config.bubbleSpawnInterval = Int($0) }
                    ), in: 5...80, step: 1) {
                        Text("Ambient Bubbles")
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.config.fishBubbleChance) },
                        set: { viewModel.config.fishBubbleChance = Int($0) }
                    ), in: 10...500, step: 1) {
                        Text("Fish Bubble Chance: 1 in \(viewModel.config.fishBubbleChance)")
                    }
                }

                Section("Creatures & Scenery") {
                    Slider(value: Binding(
                        get: { Double(viewModel.config.crabCount) },
                        set: { viewModel.config.crabCount = Int($0) }
                    ), in: 0...6, step: 1) {
                        Text("Crabs: \(viewModel.config.crabCount)")
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.config.maxJellyfish) },
                        set: { viewModel.config.maxJellyfish = Int($0) }
                    ), in: 0...5, step: 1) {
                        Text("Max Jellyfish: \(viewModel.config.maxJellyfish)")
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.config.seaweedDensity) },
                        set: { viewModel.config.seaweedDensity = Int($0) }
                    ), in: 5...60, step: 1) {
                        Text("Seaweed Density")
                    }
                    HStack {
                        Toggle("Jellyfish", isOn: $viewModel.config.jellyfishEnabled)
                        Toggle("Treasure Chest", isOn: $viewModel.config.treasureChestEnabled)
                    }
                }

                Section("Rare Events (Spawn Interval)") {
                    eventSlider(label: "Shark", value: Binding(
                        get: { Double(viewModel.config.sharkSpawnInterval) },
                        set: { viewModel.config.sharkSpawnInterval = Int($0) }
                    ), enabled: $viewModel.config.sharksEnabled, range: 10...180)
                    
                    eventSlider(label: "Whale", value: Binding(
                        get: { Double(viewModel.config.whaleSpawnInterval) },
                        set: { viewModel.config.whaleSpawnInterval = Int($0) }
                    ), enabled: $viewModel.config.whalesEnabled, range: 10...180)
                    
                    eventSlider(label: "Sea Monster", value: Binding(
                        get: { Double(viewModel.config.monsterSpawnInterval) },
                        set: { viewModel.config.monsterSpawnInterval = Int($0) }
                    ), enabled: $viewModel.config.monstersEnabled, range: 20...300)
                    
                    eventSlider(label: "Ship", value: Binding(
                        get: { Double(viewModel.config.shipSpawnInterval) },
                        set: { viewModel.config.shipSpawnInterval = Int($0) }
                    ), enabled: $viewModel.config.shipsEnabled, range: 10...120)
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            footer
        }
        .frame(width: 500, height: 620)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("><((('>  ASCII Fishtank  <')))><")
                .font(.headline)
            Text("Settings are applied on next screensaver launch.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
    }

    private var footer: some View {
        HStack {
            Button("Reset Defaults") {
                viewModel.reset()
            }
            Spacer()
            Button("Cancel") {
                onCancel()
            }
            Button("OK") {
                viewModel.save()
                onOK()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    private func eventSlider(label: String, value: Binding<Double>, enabled: Binding<Bool>, range: ClosedRange<Double>) -> some View {
        HStack {
            Slider(value: value, in: range, step: 1) {
                Text("\(label): \(Int(value.wrappedValue))s")
            }
            .disabled(!enabled.wrappedValue)
            Toggle("", isOn: enabled)
                .labelsHidden()
        }
    }
}
