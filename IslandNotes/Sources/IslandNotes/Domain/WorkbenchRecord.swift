import Foundation
import SwiftData

@Model
final class WorkbenchRecord {
    static let primaryKey = "primary"

    @Attribute(.unique) var singletonKey: String
    var currentNoteID: UUID

    init(singletonKey: String = WorkbenchRecord.primaryKey, currentNoteID: UUID) {
        self.singletonKey = singletonKey
        self.currentNoteID = currentNoteID
    }
}
