import ActivityKit
import Foundation

struct IslandNoteActivityAttributes: ActivityAttributes, Equatable {
    struct ContentState: Codable, Hashable, Sendable {
        let body: String
        let version: Int
    }

    let noteID: UUID
}
