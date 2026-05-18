// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import Foundation
import AppKit

// MARK: - Parsed art file

/// Raw result of parsing one .txt art file.
struct ParsedArtFile {
    var width: Int?
    var height: Int?
    /// Keys are lowercased section names; values are the literal art lines.
    var sections: [String: [String]] = [:]

    /// Parse a string in the section-header format.
    static func parse(_ text: String) -> ParsedArtFile {
        var result = ParsedArtFile()
        var currentSection: String? = nil

        for rawLine in text.components(separatedBy: "\n") {
            // Strip only the trailing newline that components() already ate;
            // preserve all other whitespace — it's part of the ASCII art.
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine

            if line.hasPrefix("#") { continue }   // comment

            if line.hasPrefix("@") {
                let directive = line.dropFirst()   // strip @
                if directive.lowercased().hasPrefix("width") {
                    let parts = directive.split(separator: " ", maxSplits: 1)
                    if parts.count == 2, let v = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                        result.width = v
                    }
                } else if directive.lowercased().hasPrefix("height") {
                    let parts = directive.split(separator: " ", maxSplits: 1)
                    if parts.count == 2, let v = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                        result.height = v
                    }
                } else if directive.lowercased().hasPrefix("section") {
                    let parts = directive.split(separator: " ", maxSplits: 1)
                    if parts.count == 2 {
                        let name = parts[1].trimmingCharacters(in: .whitespaces).lowercased()
                        currentSection = name
                        result.sections[name] = []   // create even if empty
                    }
                }
                continue
            }

            if let sec = currentSection {
                result.sections[sec, default: []].append(line)
            }
        }

        // Strip leading/trailing blank lines from each section, but keep
        // internal blank lines (they are intentional art rows).
        for key in result.sections.keys {
            var lines = result.sections[key]!
            while lines.first?.trimmingCharacters(in: .whitespaces).isEmpty == true { lines.removeFirst() }
            while lines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { lines.removeLast() }
            result.sections[key] = lines
        }

        return result
    }
}

// MARK: - Bundle locator

/// Finds the saver's own bundle (not Bundle.main, which is the host app).
enum ArtBundleLocator {
    static var bundle: Bundle { Bundle(for: AsciiFishtankView.self) }

    /// All .txt files in Art/<folder>, sorted alphabetically.
    static func urls(inFolder folder: String) -> [URL] {
        guard let resourceURL = bundle.resourceURL else { return [] }
        let folderURL = resourceURL.appendingPathComponent("Art/\(folder)")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }
        return contents
            .filter { $0.pathExtension == "txt" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Single named file in Art/<folder>/<filename>.txt
    static func url(forFile filename: String, inFolder folder: String) -> URL? {
        bundle.url(forResource: filename, withExtension: "txt",
                   subdirectory: "Art/\(folder)")
    }
}

// MARK: - Typed loaders

enum ArtLoader {

    // MARK: Fish

    /// Load one FishDesign from a ParsedArtFile.
    static func fishDesign(from parsed: ParsedArtFile) -> FishDesign? {
        guard let w = parsed.width, let h = parsed.height,
              let right = parsed.sections["right"], !right.isEmpty,
              let left  = parsed.sections["left"],  !left.isEmpty
        else { return nil }
        return FishDesign(
            rightArt: right,
            leftArt: left,
            rightMask: parsed.sections["right.mask"],
            leftMask: parsed.sections["left.mask"],
            width: w,
            height: h
        )
    }

    /// Load every fish TXT file found in Art/Fish/, plus the builtin fallbacks.
    static func loadAllFishDesigns() -> [FishDesign] {
        var designs: [FishDesign] = []
        for url in ArtBundleLocator.urls(inFolder: "Fish") {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let parsed = ParsedArtFile.parse(text)
            if let d = fishDesign(from: parsed) {
                designs.append(d)
            }
        }
        // Always fall back to builtins if no files were found.
        return designs.isEmpty ? FishDesign.builtinDesigns : designs
    }

    // MARK: Shark

    static func loadShark() -> (right: [String], left: [String], width: Int, height: Int)? {
        guard let url = ArtBundleLocator.url(forFile: "shark", inFolder: "Shark"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let w = p.width, let h = p.height,
              let right = p.sections["right"], !right.isEmpty,
              let left  = p.sections["left"],  !left.isEmpty
        else { return nil }
        return (right, left, w, h)
    }

    // MARK: Whale

    struct WhaleArt {
        let rightBody: [String]
        let leftBody: [String]
        let spoutFrames: [[String]]   // index 0 may be empty = no spout
        let width: Int
        let height: Int
    }

    static func loadWhale() -> WhaleArt? {
        guard let url = ArtBundleLocator.url(forFile: "whale", inFolder: "Whale"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let w = p.width, let h = p.height,
              let right = p.sections["body.right"], !right.isEmpty,
              let left  = p.sections["body.left"],  !left.isEmpty
        else { return nil }

        // Collect spout.0, spout.1, ... in order until no more found.
        var spout: [[String]] = []
        var i = 0
        while true {
            let key = "spout.\(i)"
            if p.sections[key] != nil {
                spout.append(p.sections[key]!)   // may be empty (no-spout frame)
                i += 1
            } else { break }
        }
        return WhaleArt(rightBody: right, leftBody: left,
                        spoutFrames: spout, width: w, height: h)
    }

    // MARK: Monster

    struct MonsterArt {
        let rightFrames: [[String]]
        let leftFrames: [[String]]
        let width: Int
        let height: Int
    }

    static func loadMonster() -> MonsterArt? {
        guard let url = ArtBundleLocator.url(forFile: "monster", inFolder: "Monster"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let w = p.width, let h = p.height else { return nil }
        let right = collectFrames(prefix: "right", from: p)
        let left  = collectFrames(prefix: "left",  from: p)
        guard !right.isEmpty, !left.isEmpty else { return nil }
        return MonsterArt(rightFrames: right, leftFrames: left, width: w, height: h)
    }

    // MARK: Ship

    static func loadShip() -> (right: [String], left: [String], width: Int, height: Int)? {
        guard let url = ArtBundleLocator.url(forFile: "ship", inFolder: "Ship"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let w = p.width, let h = p.height,
              let right = p.sections["right"], !right.isEmpty,
              let left  = p.sections["left"],  !left.isEmpty
        else { return nil }
        return (right, left, w, h)
    }

    // MARK: Jellyfish

    static func loadJellyfish() -> (expanded: [String], contracted: [String])? {
        guard let url = ArtBundleLocator.url(forFile: "jellyfish", inFolder: "Jellyfish"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let exp = p.sections["expanded"],    !exp.isEmpty,
              let con = p.sections["contracted"],  !con.isEmpty
        else { return nil }
        return (exp, con)
    }

    // MARK: Crab

    struct CrabArt {
        let rightFrames: [[String]]
        let leftFrames: [[String]]
        let width: Int
        let height: Int
    }

    static func loadCrab() -> CrabArt? {
        guard let url = ArtBundleLocator.url(forFile: "crab", inFolder: "Crab"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let w = p.width, let h = p.height else { return nil }
        let right = collectFrames(prefix: "right", from: p)
        let left  = collectFrames(prefix: "left",  from: p)
        guard !right.isEmpty, !left.isEmpty else { return nil }
        return CrabArt(rightFrames: right, leftFrames: left, width: w, height: h)
    }

    // MARK: Splat

    static func loadSplat() -> [[String]] {
        guard let url = ArtBundleLocator.url(forFile: "splat", inFolder: "Splat"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }
        let p = ParsedArtFile.parse(text)
        return collectFrames(prefix: "frame", from: p)
    }

    // MARK: Treasure chest

    static func loadChest() -> (open: [String], closed: [String])? {
        guard let url = ArtBundleLocator.url(forFile: "chest", inFolder: "TreasureChest"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let open   = p.sections["open"],   !open.isEmpty,
              let closed = p.sections["closed"], !closed.isEmpty
        else { return nil }
        return (open, closed)
    }

    // MARK: Decorations

    struct DecorationArt {
        let castle: [String]
        let castleWidth: Int
        let castleHeight: Int
        let rocks: [[String]]
        let shells: [(art: String, color: NSColor)]
    }

    static func loadDecorations() -> DecorationArt? {
        guard let url = ArtBundleLocator.url(forFile: "decorations", inFolder: "Decorations"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        let p = ParsedArtFile.parse(text)
        guard let castle = p.sections["castle"], !castle.isEmpty else { return nil }

        let rocks  = collectFrames(prefix: "rock",  from: p)

        // Shells are single-line art with alternating colors.
        var shells: [(art: String, color: NSColor)] = []
        var si = 0
        while let lines = p.sections["shell.\(si)"], !lines.isEmpty {
            let art = lines[0]
            // Lines containing "*" are starfish-colored; everything else uses shell color.
            let isStarfish = art.contains("*")
            shells.append((art: art, color: isStarfish ? ColorPalette.starfish : ColorPalette.shell))
            si += 1
        }

        let cw = castle.map { $0.count }.max() ?? DecorationEntity.castleWidth
        let ch = castle.count
        return DecorationArt(castle: castle, castleWidth: cw, castleHeight: ch,
                             rocks: rocks, shells: shells)
    }

    // MARK: - Helpers

    /// Collect sections named "<prefix>.0", "<prefix>.1", ... in order.
    private static func collectFrames(prefix: String, from p: ParsedArtFile) -> [[String]] {
        var frames: [[String]] = []
        var i = 0
        while let lines = p.sections["\(prefix).\(i)"] {
            frames.append(lines)
            i += 1
        }
        return frames
    }
}

// MARK: - Art repository (loaded once at startup)

final class ArtRepository {
    private static var _shared: ArtRepository?
    static var shared: ArtRepository {
        if _shared == nil {
            _shared = ArtRepository()
        }
        return _shared!
    }
    
    static func free() {
        _shared = nil
    }

    let fishDesigns: [FishDesign]
    let sharkRight: [String]
    let sharkLeft: [String]
    let sharkWidth: Int
    let sharkHeight: Int

    let whaleRightBody: [String]
    let whaleLeftBody: [String]
    let whaleSpoutFrames: [[String]]
    let whaleWidth: Int
    let whaleHeight: Int

    let monsterRightFrames: [[String]]
    let monsterLeftFrames: [[String]]
    let monsterWidth: Int
    let monsterHeight: Int

    let shipRight: [String]
    let shipLeft: [String]
    let shipWidth: Int
    let shipHeight: Int

    let jellyfishExpanded: [String]
    let jellyfishContracted: [String]

    let crabRightFrames: [[String]]
    let crabLeftFrames: [[String]]
    let crabWidth: Int
    let crabHeight: Int

    let splatFrames: [[String]]

    let chestOpen: [String]
    let chestClosed: [String]

    let decorationArt: ArtLoader.DecorationArt?

    private init() {
        // Fish
        fishDesigns = ArtLoader.loadAllFishDesigns()

        // Shark
        if let s = ArtLoader.loadShark() {
            sharkRight = s.right; sharkLeft = s.left
            sharkWidth = s.width; sharkHeight = s.height
        } else {
            sharkRight = SharkEntity.builtinRightArt; sharkLeft = SharkEntity.builtinLeftArt
            sharkWidth = SharkEntity.builtinWidth;    sharkHeight = SharkEntity.builtinHeight
        }

        // Whale
        if let wh = ArtLoader.loadWhale() {
            whaleRightBody = wh.rightBody; whaleLeftBody = wh.leftBody
            whaleSpoutFrames = wh.spoutFrames
            whaleWidth = wh.width; whaleHeight = wh.height
        } else {
            whaleRightBody = WhaleEntity.builtinRightArt; whaleLeftBody = WhaleEntity.builtinLeftArt
            whaleSpoutFrames = WhaleEntity.builtinSpoutFrames
            whaleWidth = WhaleEntity.builtinWidth; whaleHeight = WhaleEntity.builtinHeight
        }

        // Monster
        if let m = ArtLoader.loadMonster() {
            monsterRightFrames = m.rightFrames; monsterLeftFrames = m.leftFrames
            monsterWidth = m.width; monsterHeight = m.height
        } else {
            monsterRightFrames = MonsterEntity.builtinRightFrames
            monsterLeftFrames  = MonsterEntity.builtinLeftFrames
            monsterWidth = MonsterEntity.builtinWidth; monsterHeight = MonsterEntity.builtinHeight
        }

        // Ship
        if let sh = ArtLoader.loadShip() {
            shipRight = sh.right; shipLeft = sh.left
            shipWidth = sh.width; shipHeight = sh.height
        } else {
            shipRight = ShipEntity.builtinRightArt; shipLeft = ShipEntity.builtinLeftArt
            shipWidth = ShipEntity.builtinWidth;    shipHeight = ShipEntity.builtinHeight
        }

        // Jellyfish
        if let jf = ArtLoader.loadJellyfish() {
            jellyfishExpanded = jf.expanded; jellyfishContracted = jf.contracted
        } else {
            jellyfishExpanded   = JellyfishEntity.builtinExpandedArt
            jellyfishContracted = JellyfishEntity.builtinContractedArt
        }

        // Crab
        if let cr = ArtLoader.loadCrab() {
            crabRightFrames = cr.rightFrames; crabLeftFrames = cr.leftFrames
            crabWidth = cr.width; crabHeight = cr.height
        } else {
            crabRightFrames = CrabEntity.builtinRightFrames
            crabLeftFrames  = CrabEntity.builtinLeftFrames
            crabWidth = CrabEntity.builtinWidth; crabHeight = CrabEntity.builtinHeight
        }

        // Splat
        let sp = ArtLoader.loadSplat()
        splatFrames = sp.isEmpty ? SplatEntity.builtinFrames : sp

        // Treasure chest
        if let ch = ArtLoader.loadChest() {
            chestOpen = ch.open; chestClosed = ch.closed
        } else {
            chestOpen = TreasureChest.builtinOpenArt; chestClosed = TreasureChest.builtinClosedArt
        }

        // Decorations
        decorationArt = ArtLoader.loadDecorations()
    }
}
