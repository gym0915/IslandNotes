import SwiftData
import SwiftUI

@main
struct IslandNotesApp: App {
    nonisolated static let minimumSupportedMajorVersion = 17

    private let container: ModelContainer
    private let liveActivityController: any LiveActivityControlling
    private let initialDeepLink: URL?
    private let simulatesSaveFailure: Bool
    @State private var appearance: AppearanceSettings

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        _appearance = State(
            initialValue: AppearanceSettings(
                defaults: Self.appearanceDefaults(arguments: arguments)
            )
        )
        let isUITesting = arguments.contains("--uitesting-reset")
        simulatesSaveFailure = arguments.contains("--uitesting-save-failure")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
        container = try! ModelContainer(
            for: NoteRecord.self,
            WorkbenchRecord.self,
            configurations: configuration
        )
        if simulatesSaveFailure {
            let timestamp = Date(timeIntervalSince1970: 1_000)
            let note = NoteRecord(
                body: "Last committed source",
                contentVersion: 3,
                createdAt: timestamp,
                modifiedAt: timestamp
            )
            container.mainContext.insert(note)
            container.mainContext.insert(WorkbenchRecord(currentNoteID: note.id))
            try! container.mainContext.save()
        }
#if DEBUG
        switch LiveActivityControllerSelection.mode(arguments: arguments) {
        case .system:
            liveActivityController = ActivityKitLiveActivityController()
        case .deterministicUITest:
            liveActivityController = DeterministicUITestLiveActivityController()
        }
#else
        liveActivityController = ActivityKitLiveActivityController()
#endif
        initialDeepLink = Self.uiTestingDeepLink(from: arguments)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                modelContext: container.mainContext,
                liveActivityController: liveActivityController,
                appearance: appearance,
                initialDeepLink: initialDeepLink,
                simulatesSaveFailure: simulatesSaveFailure
            )
            .preferredColorScheme(appearance.mode.colorScheme)
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

    private static func appearanceDefaults(arguments: [String]) -> UserDefaults {
        guard let flagIndex = arguments.firstIndex(of: "--uitesting-appearance-suite"),
              arguments.indices.contains(flagIndex + 1) else {
            return .standard
        }

        let suiteName = arguments[flagIndex + 1]
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        if arguments.contains("--uitesting-reset-appearance") {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}
