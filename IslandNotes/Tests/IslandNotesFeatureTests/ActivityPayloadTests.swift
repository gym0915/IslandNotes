import XCTest
@testable import IslandNotes

final class ActivityPayloadTests: XCTestCase {
    private let noteID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    func testAttributesAndContentStateRoundTripVerbatim() throws {
        let attributes = IslandNoteActivityAttributes(noteID: noteID)
        let state = IslandNoteActivityAttributes.ContentState(
            body: "中文  two spaces\n👨‍👩‍👧‍👦",
            version: 7
        )

        let decodedAttributes = try JSONDecoder().decode(
            IslandNoteActivityAttributes.self,
            from: JSONEncoder().encode(attributes)
        )
        let decodedState = try JSONDecoder().decode(
            IslandNoteActivityAttributes.ContentState.self,
            from: JSONEncoder().encode(state)
        )

        XCTAssertEqual(decodedAttributes.noteID, noteID)
        XCTAssertEqual(decodedState, state)
    }

    func testEncodedByteCountUsesTheFinalProductionJSONRepresentations() throws {
        let attributes = IslandNoteActivityAttributes(noteID: noteID)
        let state = IslandNoteActivityAttributes.ContentState(body: "原样正文", version: 3)

        let expected = try JSONEncoder().encode(attributes).count
            + JSONEncoder().encode(state).count

        XCTAssertEqual(
            try ActivityPayloadSizer.encodedByteCount(attributes: attributes, state: state),
            expected
        )
    }

    func testRepresentative240CharacterPayloadsAreMeasuredIndependentlyOfCharacterCount() throws {
        let attributes = IslandNoteActivityAttributes(noteID: noteID)
        let samples = [
            String(repeating: "a", count: 240),
            String(repeating: "中", count: 240),
            String(repeating: "😀", count: 240)
        ]

        for body in samples {
            XCTAssertEqual(body.count, 240)
            let state = IslandNoteActivityAttributes.ContentState(body: body, version: 1)
            XCTAssertNoThrow(try ActivityPayloadSizer.validate(attributes: attributes, state: state))
        }
    }

    func test240ComplexGraphemesCanFailTheFourKilobyteCheckWithoutChangingCharacterCount() throws {
        let attributes = IslandNoteActivityAttributes(noteID: noteID)
        let body = String(repeating: "👨🏽‍👩🏾‍👧🏿‍👦🏻", count: 240)
        let state = IslandNoteActivityAttributes.ContentState(body: body, version: 1)

        XCTAssertEqual(body.count, 240)
        XCTAssertThrowsError(try ActivityPayloadSizer.validate(attributes: attributes, state: state)) { error in
            guard case let ActivityPayloadError.exceedsLimit(actualBytes, maximumBytes) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertGreaterThan(actualBytes, maximumBytes)
            XCTAssertEqual(maximumBytes, 4_096)
        }
    }
}
