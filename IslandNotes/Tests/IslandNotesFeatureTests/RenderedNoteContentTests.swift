import XCTest
@testable import IslandNotes

final class RenderedNoteContentTests: XCTestCase {
    func testOnlyExactLeadingHyphenSpaceLinesBecomeBullets() {
        let source = """
        Plain text
        - First bullet

        # heading stays literal
        * star stays literal
        -missing space
         - indented stays literal
        - 👨‍👩‍👧‍👦 family bullet
        """

        XCTAssertEqual(
            RenderedNoteContent.lines(from: source),
            [
                .text("Plain text"),
                .bullet("First bullet"),
                .text(""),
                .text("# heading stays literal"),
                .text("* star stays literal"),
                .text("-missing space"),
                .text(" - indented stays literal"),
                .bullet("👨‍👩‍👧‍👦 family bullet"),
            ]
        )
    }

    func testRendererPreservesTrailingBlankSourceLines() {
        XCTAssertEqual(
            RenderedNoteContent.lines(from: "First\n\n"),
            [.text("First"), .text(""), .text("")]
        )
    }

    func testDisplayStringUsesBulletGlyphsWithoutParsingOtherMarkdown() {
        XCTAssertEqual(
            RenderedNoteContent.displayString(
                from: "Plain\n- Bullet\n# heading\n* star\n- "
            ),
            "Plain\n• Bullet\n# heading\n* star\n• "
        )
    }
}
