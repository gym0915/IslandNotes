import Foundation
import Observation

enum AppSheet: String, Equatable, Identifiable {
    case noteLibrary
    case settings

    var id: String { rawValue }
}

@MainActor
@Observable
final class AppRouter {
    private(set) var presentedSheet: AppSheet?

    func presentNoteLibrary() {
        presentedSheet = .noteLibrary
    }

    func presentSettings() {
        presentedSheet = .settings
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    @discardableResult
    func handleDeepLink(_ url: URL) -> Bool {
        guard DeepLinkRouter.destination(for: url) == .workbench else { return false }
        presentedSheet = nil
        return true
    }
}
