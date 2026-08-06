import Foundation

enum NoteContent {
    static func isActionable(_ body: String) -> Bool {
        body.unicodeScalars.contains {
            !CharacterSet.whitespacesAndNewlines.contains($0)
        }
    }
}
