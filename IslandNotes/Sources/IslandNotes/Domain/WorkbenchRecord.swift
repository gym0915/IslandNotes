import Foundation
import SwiftData

@Model
final class WorkbenchRecord {
    @Attribute(.unique) var singletonKey: String
    var currentNoteID: UUID

    init(singletonKey: String = "primary", currentNoteID: UUID) {
        self.singletonKey = singletonKey
        self.currentNoteID = currentNoteID
    }
}
