import Foundation
import SwiftData

@Model
final class NoteRecord {
    @Attribute(.unique) var id: UUID
    var body: String
    var contentVersion: Int = 0
    var createdAt: Date
    var modifiedAt: Date
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        body: String = "",
        contentVersion: Int = 0,
        createdAt: Date,
        modifiedAt: Date,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.body = body
        self.contentVersion = contentVersion
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.archivedAt = archivedAt
    }
}
