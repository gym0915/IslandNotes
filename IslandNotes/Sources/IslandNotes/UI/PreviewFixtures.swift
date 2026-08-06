#if DEBUG
import SwiftData
import SwiftUI

@MainActor
private final class PreviewLiveActivityController: LiveActivityControlling {
    func activities() async -> [ActivitySession] { [] }
    func request(noteID: UUID, body: String, version: Int) async throws {}
    func update(activityID: String, body: String, version: Int) async throws {}
    func end(activityID: String) async throws {}
}

@MainActor
private enum PreviewFixtures {
    static func workbench(
        body: String = "",
        pinState: PinState = .unpinned,
        libraryBodies: [String] = [],
        reachedLimit: Bool = false,
        feedback: String? = nil,
        deleting: Bool = false,
        reduceMotion: Bool? = nil
    ) -> some View {
        let fixture = makeFeature(
            body: body,
            pinState: pinState,
            libraryBodies: libraryBodies,
            reachedLimit: reachedLimit,
            feedback: feedback,
            deleting: deleting
        )

        return NavigationStack {
            WorkbenchView(
                feature: fixture.feature,
                reduceMotionOverride: reduceMotion,
                openNoteLibrary: {},
                openSettings: {}
            )
        }
        .modelContainer(fixture.container)
    }

    static func library(libraryBodies: [String]) -> some View {
        let fixture = makeFeature(body: "", libraryBodies: libraryBodies)
        return AppSheetContainer(title: "Note Library", close: {}) {
            NoteLibraryView(feature: fixture.feature)
        }
        .modelContainer(fixture.container)
    }

    static func settings() -> some View {
        AppSheetContainer(title: "Settings", close: {}) {
            SettingsView()
        }
    }

    static func moreMenu() -> some View {
        ZStack(alignment: .topTrailing) {
            IslandDesign.Colors.canvas
                .ignoresSafeArea()
            MoreMenu(openNoteLibrary: {}, openSettings: {})
                .padding(IslandDesign.Spacing.x6)
        }
    }

    private static func makeFeature(
        body: String,
        pinState: PinState = .unpinned,
        libraryBodies: [String] = [],
        reachedLimit: Bool = false,
        feedback: String? = nil,
        deleting: Bool = false
    ) -> (feature: IslandNotesFeature, container: ModelContainer) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: NoteRecord.self,
            WorkbenchRecord.self,
            configurations: configuration
        )
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let current = NoteRecord(
            body: body,
            contentVersion: 3,
            createdAt: now.addingTimeInterval(-600),
            modifiedAt: now
        )
        let library = libraryBodies.enumerated().map { index, body in
            NoteRecord(
                body: body,
                contentVersion: index + 1,
                createdAt: now.addingTimeInterval(TimeInterval(-3_600 * (index + 2))),
                modifiedAt: now.addingTimeInterval(TimeInterval(-600 * (index + 1))),
                archivedAt: now.addingTimeInterval(TimeInterval(-300 * (index + 1)))
            )
        }
        let context = container.mainContext
        ([current] + library).forEach(context.insert)
        context.insert(WorkbenchRecord(currentNoteID: current.id))
        try! context.save()

        let feature = IslandNotesFeature.preview(
            modelContext: context,
            liveActivityController: PreviewLiveActivityController(),
            records: [current] + library,
            currentNoteID: current.id,
            pinState: pinState,
            didReachCharacterLimit: reachedLimit,
            isCharacterCountVisible: reachedLimit,
            deleteConfirmation: deleting ? .pending(message: "This cannot be undone.") : nil,
            feedbackMessage: feedback
        )
        return (feature, container)
    }
}

#Preview("Workbench · Empty") {
    PreviewFixtures.workbench()
}

#Preview("App Shell · Light") {
    PreviewFixtures.workbench(body: "A clear place for what matters now.")
        .preferredColorScheme(.light)
}

#Preview("App Shell · Dark") {
    PreviewFixtures.workbench(body: "A clear place for what matters now.")
        .preferredColorScheme(.dark)
}

#Preview("More Menu · Light") {
    PreviewFixtures.moreMenu()
        .preferredColorScheme(.light)
}

#Preview("More Menu · Dark") {
    PreviewFixtures.moreMenu()
        .preferredColorScheme(.dark)
}

#Preview("Note Library Sheet · Light") {
    PreviewFixtures.library(
        libraryBodies: ["Call home before boarding", "Review the launch notes"]
    )
    .preferredColorScheme(.light)
}

#Preview("Settings Sheet · Dark") {
    PreviewFixtures.settings()
        .preferredColorScheme(.dark)
}

#Preview("Workbench · Short Note") {
    PreviewFixtures.workbench(body: "Call home before boarding.")
}

#Preview("Workbench · Multilingual and Emoji") {
    PreviewFixtures.workbench(body: "Ship the tiny thing.\n然后去散步 🌿👨‍👩‍👧‍👦")
}

#Preview("Workbench · 239 Characters") {
    PreviewFixtures.workbench(body: String(repeating: "字", count: 239))
}

#Preview("Workbench · 240 Characters") {
    PreviewFixtures.workbench(body: String(repeating: "A", count: 240))
}

#Preview("Workbench · Character Limit") {
    PreviewFixtures.workbench(
        body: String(repeating: "界", count: 240),
        reachedLimit: true
    )
}

#Preview("Workbench · Live") {
    PreviewFixtures.workbench(body: "This note is currently Live.", pinState: .pinned)
}

#Preview("Workbench · Update Not Synchronized") {
    PreviewFixtures.workbench(
        body: "This note is saved on this device.",
        pinState: .pinned,
        feedback: "Live may not be up to date."
    )
}

#Preview("Workbench · Delete Confirmation") {
    PreviewFixtures.workbench(body: "A note ready to delete", deleting: true)
}

#Preview("Workbench · Dark") {
    PreviewFixtures.workbench(body: "The shell follows the dark appearance.")
        .preferredColorScheme(.dark)
}

#Preview("Workbench · Maximum Dynamic Type") {
    PreviewFixtures.workbench(body: "All actions remain reachable at the largest text size.")
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Workbench · Reduce Motion") {
    PreviewFixtures.workbench(
        body: "State is never communicated through motion alone.",
        pinState: .pinned,
        reduceMotion: true
    )
}

#Preview("Note Library · Empty") {
    PreviewFixtures.library(libraryBodies: [])
}

#Preview("Note Library · Populated") {
    PreviewFixtures.library(
        libraryBodies: [
            "Most recently moved note\nLine breaks remain intact",
            "Second note with an emoji 🧭",
            "An earlier note",
        ]
    )
}
#endif
