import XCTest
@testable import AsciiFishtank

final class ArtLoaderTests: XCTestCase {
    func testParsedArtFile() {
        let text = """
        @width 10
        @height 3
        @section right
        ---
        |o|
        ---
        """
        let parsed = ParsedArtFile.parse(text)
        XCTAssertEqual(parsed.width, 10)
        XCTAssertEqual(parsed.height, 3)
        XCTAssertEqual(parsed.sections["right"]?.count, 3)
        XCTAssertEqual(parsed.sections["right"]?[1], "|o|")
    }

    func testParsedArtFileSections() {
        let text = """
        @section a
        line1
        line2
        @section b
        line3
        """
        let parsed = ParsedArtFile.parse(text)
        XCTAssertEqual(parsed.sections["a"], ["line1", "line2"])
        XCTAssertEqual(parsed.sections["b"], ["line3"])
    }
}
