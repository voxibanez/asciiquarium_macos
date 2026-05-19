// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit
import Foundation

class WaterSurface {
    let columns: Int
    var phase: Double = 0.0

    // Row where water starts (below border)
    let startRow = 1

    // Pre-allocated scratch buffer to avoid per-frame heap allocation.
    // Stores sin values for each column (3 rows × columns).
    private var sinBuf: [Double]

    init(columns: Int) {
        self.columns = columns
        self.sinBuf = [Double](repeating: 0, count: columns * 3)
    }

    func tick() {
        phase += 0.04
    }

    func render(into grid: GridRenderer) {
        // Pre-compute all sin values in one pass to avoid redundant trig calls.
        // Row 0: sin(phase + col * 0.3)
        // Row 1: sin(phase * 0.8 + col * 0.25 + 1.0)
        // Row 2: sin(phase * 0.6 + col * 0.15 + 2.5)
        let p0 = phase
        let p1 = phase * 0.8 + 1.0
        let p2 = phase * 0.6 + 2.5

        for col in 1..<(columns - 1) {
            let fc = Double(col)
            sinBuf[col]              = sin(p0 + fc * 0.3)
            sinBuf[columns + col]   = sin(p1 + fc * 0.25)
            sinBuf[columns*2 + col] = sin(p2 + fc * 0.15)
        }

        // Row 1: top wave line
        for col in 1..<(columns - 1) {
            let wave = sinBuf[col]
            let ch: Character = wave > 0.3 ? "^" : "~"
            let color = wave > 0.0 ? ColorPalette.waterSurfaceLight : ColorPalette.waterSurface
            grid.putChar(ch, at: col, row: startRow, foreground: color)
        }

        // Row 2: secondary wave
        for col in 1..<(columns - 1) {
            let wave = sinBuf[columns + col]
            if wave > 0.4 {
                grid.putChar("~", at: col, row: startRow + 1, foreground: ColorPalette.waterSurface)
            } else if wave > 0.1 {
                grid.putChar("^", at: col, row: startRow + 1, foreground: ColorPalette.waterSurface)
            }
        }

        // Row 3: sparse ripples
        for col in 1..<(columns - 1) {
            let wave = sinBuf[columns*2 + col]
            if wave > 0.6 {
                grid.putChar("~", at: col, row: startRow + 2, foreground: ColorPalette.waterSurface)
            }
        }
    }
}
