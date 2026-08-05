import Foundation

enum DeepLinkDestination: Equatable, Sendable {
    case workbench
}

enum DeepLinkRouter {
    static func destination(for url: URL) -> DeepLinkDestination? {
        guard url.scheme?.lowercased() == "islandnotes",
              url.host?.lowercased() == "workbench" else {
            return nil
        }

        // Query items, including historical note IDs, are deliberately ignored.
        return .workbench
    }
}
