import Foundation

enum RenderedNoteLine: Equatable, Sendable {
    case text(String)
    case bullet(String)
}

enum RenderedNoteContent {
    static func lines(from source: String) -> [RenderedNoteLine] {
        guard !source.isEmpty else { return [] }

        return source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                guard line.hasPrefix("- ") else {
                    return .text(String(line))
                }
                return .bullet(String(line.dropFirst(2)))
            }
    }
}
