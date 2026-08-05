import SwiftData
import SwiftUI

@main
struct IslandNotesApp: App {
    nonisolated static let minimumSupportedMajorVersion = 17

    private let container: ModelContainer
    private let liveActivityController: ActivityKitLiveActivityController
    private let initialDeepLink: URL?

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting-reset")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
        container = try! ModelContainer(
            for: NoteRecord.self,
            WorkbenchRecord.self,
            configurations: configuration
        )
        liveActivityController = ActivityKitLiveActivityController()
        initialDeepLink = Self.uiTestingDeepLink(from: ProcessInfo.processInfo.arguments)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                modelContext: container.mainContext,
                liveActivityController: liveActivityController,
                initialDeepLink: initialDeepLink
            )
        }
        .modelContainer(container)
    }

    private static func uiTestingDeepLink(from arguments: [String]) -> URL? {
        guard let flagIndex = arguments.firstIndex(of: "--uitesting-open-url"),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }
        return URL(string: arguments[flagIndex + 1])
    }
}
