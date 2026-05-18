// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import AppKit
import Foundation

@main
enum ArtLoaderTestRunner {
    static func main() {
        let suite = TestSuite()

        suite.test("ParsedArtFile reads dimensions and sections") {
            let parsed = ParsedArtFile.parse("""
            @width 10
            @height 3
            @section right
            ---
            |o|
            ---
            """)

            suite.expectEqual(parsed.width, 10)
            suite.expectEqual(parsed.height, 3)
            suite.expectEqual(parsed.sections["right"], ["---", "|o|", "---"])
        }

        suite.test("Parser ignores comments and trims outer blank lines only") {
            let parsed = ParsedArtFile.parse("""
            # SPDX-License-Identifier: GPL-2.0-or-later
            @section body

              top

              bottom

            # ignored
            """)

            suite.expectEqual(parsed.sections["body"], ["  top", "", "  bottom"])
        }

        suite.test("Parser handles tabs, case, and carriage returns") {
            let parsed = ParsedArtFile.parse("@WIDTH\t12\r\n@HEIGHT\t4\r\n@SECTION\tBody.Right\r\nfish\r\n")

            suite.expectEqual(parsed.width, 12)
            suite.expectEqual(parsed.height, 4)
            suite.expectEqual(parsed.sections["body.right"], ["fish"])
        }

        suite.test("Parser ignores content before first section") {
            let parsed = ParsedArtFile.parse("""
            loose
            @section known
            kept
            """)

            suite.expectNil(parsed.sections["loose"])
            suite.expectEqual(parsed.sections["known"], ["kept"])
        }

        suite.test("Parser preserves art lines that start with at signs") {
            let parsed = ParsedArtFile.parse("""
            @section shell.0
            @>
            @section shell.1
            @@
            """)

            suite.expectEqual(parsed.sections["shell.0"], ["@>"])
            suite.expectEqual(parsed.sections["shell.1"], ["@@"])
        }

        suite.test("FishDesign requires dimensions and both directions") {
            let valid = ParsedArtFile.parse("""
            @width 5
            @height 3
            @section right
            ><
            @section left
            <>
            @section right.mask
            11
            """)

            let design = ArtLoader.fishDesign(from: valid)
            suite.expectEqual(design?.width, 5)
            suite.expectEqual(design?.height, 3)
            suite.expectEqual(design?.rightArt, ["><"])
            suite.expectEqual(design?.leftArt, ["<>"])
            suite.expectEqual(design?.rightMask, ["11"])

            let missingLeft = ParsedArtFile.parse("""
            @width 5
            @height 3
            @section right
            ><
            """)
            suite.expectNil(ArtLoader.fishDesign(from: missingLeft))
        }

        suite.test("Directional art builders share validation") {
            let parsed = ParsedArtFile.parse("""
            @width 25
            @height 6
            @section right
            right
            @section left
            left
            """)

            suite.expectEqual(ArtLoader.sharkArt(from: parsed)?.right, ["right"])
            suite.expectEqual(ArtLoader.shipArt(from: parsed)?.left, ["left"])
            suite.expectNil(ArtLoader.shipArt(from: ParsedArtFile.parse("@width 25\n@section right\nright")))
        }

        suite.test("collectFrames stops at first gap") {
            let parsed = ParsedArtFile.parse("""
            @section frame.0
            a
            @section frame.1
            b
            @section frame.3
            d
            """)

            suite.expectEqual(ArtLoader.collectFrames(prefix: "frame", from: parsed), [["a"], ["b"]])
        }

        suite.test("WhaleArt allows empty first spout frame") {
            let parsed = ParsedArtFile.parse("""
            @width 20
            @height 4
            @section body.right
            right
            @section body.left
            left
            @section spout.0

            @section spout.1
            :
            """)

            let whale = ArtLoader.whaleArt(from: parsed)
            suite.expectEqual(whale?.rightBody, ["right"])
            suite.expectEqual(whale?.leftBody, ["left"])
            suite.expectEqual(whale?.spoutFrames, [[], [":"]])
        }

        suite.test("Frame based creature art requires both directions") {
            let parsed = ParsedArtFile.parse("""
            @width 7
            @height 3
            @section right.0
            r0
            @section right.1
            r1
            @section left.0
            l0
            """)

            let crab = ArtLoader.crabArt(from: parsed)
            suite.expectEqual(crab?.rightFrames, [["r0"], ["r1"]])
            suite.expectEqual(crab?.leftFrames, [["l0"]])

            let missingLeft = ParsedArtFile.parse("""
            @width 7
            @height 3
            @section right.0
            r0
            """)
            suite.expectNil(ArtLoader.crabArt(from: missingLeft))
            suite.expectNil(ArtLoader.monsterArt(from: missingLeft))
        }

        suite.test("Single file art builders validate required sections") {
            let jellyfish = ParsedArtFile.parse("""
            @section expanded
            big
            @section contracted
            small
            """)
            suite.expectEqual(ArtLoader.jellyfishArt(from: jellyfish)?.expanded, ["big"])
            suite.expectEqual(ArtLoader.jellyfishArt(from: jellyfish)?.contracted, ["small"])

            let chest = ParsedArtFile.parse("""
            @section open
            open
            @section closed
            closed
            """)
            suite.expectEqual(ArtLoader.chestArt(from: chest)?.open, ["open"])
            suite.expectEqual(ArtLoader.chestArt(from: chest)?.closed, ["closed"])

            suite.expectNil(ArtLoader.jellyfishArt(from: ParsedArtFile.parse("@section expanded\nbig")))
            suite.expectNil(ArtLoader.chestArt(from: ParsedArtFile.parse("@section open\nopen")))
        }

        suite.test("DecorationArt computes dimensions and shell colors") {
            let parsed = ParsedArtFile.parse("""
            @section castle
            ABC
            DE
            @section rock.0
            /\\
            @section shell.0
            @>
            @section shell.1
            -*-
            """)

            let decoration = ArtLoader.decorationArt(from: parsed)
            suite.expectEqual(decoration?.castle, ["ABC", "DE"])
            suite.expectEqual(decoration?.castleWidth, 3)
            suite.expectEqual(decoration?.castleHeight, 2)
            suite.expectEqual(decoration?.rocks, [["/\\"]])
            suite.expectEqual(decoration?.shells.map(\.art), ["@>", "-*-"])
            suite.expectColorEqual(decoration?.shells[0].color, ColorPalette.shell)
            suite.expectColorEqual(decoration?.shells[1].color, ColorPalette.starfish)
        }

        suite.test("Splat frames use sequential frame sections") {
            let parsed = ParsedArtFile.parse("""
            @section frame.0
            one
            @section frame.1
            two
            """)

            suite.expectEqual(ArtLoader.splatFrames(from: parsed), [["one"], ["two"]])
        }

        suite.finish()
    }
}

final class TestSuite {
    private var failures: [String] = []

    func test(_ name: String, _ body: () -> Void) {
        print("TEST \(name)")
        body()
    }

    func expectEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #file, line: UInt = #line) {
        if actual != expected {
            fail("Expected \(String(reflecting: expected)), got \(String(reflecting: actual))", file: file, line: line)
        }
    }

    func expectNil<T>(_ actual: T?, file: StaticString = #file, line: UInt = #line) {
        if let actual {
            fail("Expected nil, got \(String(reflecting: actual))", file: file, line: line)
        }
    }

    func expectColorEqual(_ actual: NSColor?, _ expected: NSColor, file: StaticString = #file, line: UInt = #line) {
        guard let actual else {
            fail("Expected color, got nil", file: file, line: line)
            return
        }

        let lhs = actual.usingColorSpace(.deviceRGB)
        let rhs = expected.usingColorSpace(.deviceRGB)
        if lhs?.redComponent != rhs?.redComponent
            || lhs?.greenComponent != rhs?.greenComponent
            || lhs?.blueComponent != rhs?.blueComponent
            || lhs?.alphaComponent != rhs?.alphaComponent {
            fail("Expected color \(expected), got \(actual)", file: file, line: line)
        }
    }

    func finish() -> Never {
        if failures.isEmpty {
            print("All tests passed")
            Foundation.exit(0)
        }

        print("\n\(failures.count) test failure(s):")
        for failure in failures {
            print(failure)
        }
        Foundation.exit(1)
    }

    private func fail(_ message: String, file: StaticString, line: UInt) {
        failures.append("\(file):\(line): \(message)")
    }
}
