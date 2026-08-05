import Foundation

enum LiveActivityRegion: CaseIterable, Sendable {
    case compactLeading
    case compactTrailing
    case minimal
    case expanded
    case lockScreen
}

struct LiveActivityPresentation: Equatable, Sendable {
    let body: String?
    let destination: URL
}

enum LiveActivityPresentationModel {
    static let workbenchURL = URL(string: "islandnotes://workbench")!

    static func presentation(
        for region: LiveActivityRegion,
        state: IslandNoteActivityAttributes.ContentState
    ) -> LiveActivityPresentation {
        let body: String? = switch region {
        case .expanded, .lockScreen:
            state.body
        case .compactLeading, .compactTrailing, .minimal:
            nil
        }

        return LiveActivityPresentation(body: body, destination: workbenchURL)
    }
}
