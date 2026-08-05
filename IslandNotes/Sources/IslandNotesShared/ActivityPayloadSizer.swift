import Foundation

enum ActivityPayloadError: Error, Equatable {
    case exceedsLimit(actualBytes: Int, maximumBytes: Int)
}

enum ActivityPayloadSizer {
    static let maximumBytes = 4_096

    static func encodedByteCount(
        attributes: IslandNoteActivityAttributes,
        state: IslandNoteActivityAttributes.ContentState
    ) throws -> Int {
        let encoder = JSONEncoder()
        return try encoder.encode(attributes).count + encoder.encode(state).count
    }

    @discardableResult
    static func validate(
        attributes: IslandNoteActivityAttributes,
        state: IslandNoteActivityAttributes.ContentState
    ) throws -> Int {
        let actualBytes = try encodedByteCount(attributes: attributes, state: state)
        guard actualBytes <= maximumBytes else {
            throw ActivityPayloadError.exceedsLimit(
                actualBytes: actualBytes,
                maximumBytes: maximumBytes
            )
        }
        return actualBytes
    }
}
