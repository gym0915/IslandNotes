import Foundation

struct ActivitySession: Equatable, Sendable {
    let activityID: String
    let noteID: UUID
    let body: String
    let version: Int
    let isActive: Bool
}
