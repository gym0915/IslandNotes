import Foundation

enum LiveActivityRegion: CaseIterable, Sendable {
    case compactLeading
    case compactTrailing
    case minimal
    case expanded
    case lockScreen
}

enum LiveActivityBrandMark: Equatable, Sendable {
    case notebookText
}

struct LiveActivityPresentation: Equatable, Sendable {
    let brandMark: LiveActivityBrandMark?
    let body: String?
    let lineLimit: Int?
    let accessibilityLabel: String?
    let destination: URL
}

enum LiveActivityPresentationModel {
    static let workbenchURL = URL(string: "islandnotes://workbench")!

    static func presentation(
        for region: LiveActivityRegion,
        state: IslandNoteActivityAttributes.ContentState
    ) -> LiveActivityPresentation {
        let showsBrandMark = switch region {
        case .compactLeading, .minimal, .expanded, .lockScreen:
            true
        case .compactTrailing:
            false
        }
        let body: String? = switch region {
        case .expanded, .lockScreen:
            RenderedNoteContent.displayString(from: state.body)
        case .compactLeading, .compactTrailing, .minimal:
            nil
        }
        let lineLimit: Int? = switch region {
        case .expanded, .lockScreen:
            3
        case .compactLeading, .compactTrailing, .minimal:
            nil
        }
        let accessibilityLabel: String? = if let body {
            "Island Notes, \(body)"
        } else if showsBrandMark {
            "Island Notes"
        } else {
            nil
        }

        return LiveActivityPresentation(
            brandMark: showsBrandMark ? .notebookText : nil,
            body: body,
            lineLimit: lineLimit,
            accessibilityLabel: accessibilityLabel,
            destination: workbenchURL
        )
    }
}
