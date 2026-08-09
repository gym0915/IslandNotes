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

private struct AppSheetPreviewHost<Content: View>: View {
    @State private var isPresented = true
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            IslandDesign.Colors.canvas
                .ignoresSafeArea()
            Text("Island Notes")
                .font(IslandDesign.Typography.productName)
                .foregroundStyle(IslandDesign.Colors.primaryText)
                .padding(IslandDesign.Spacing.x6)
        }
        .sheet(isPresented: $isPresented) {
            content
                .islandSheetPresentationStyle()
        }
    }
}

@MainActor
private enum PreviewFixtures {
    static func workbench(
        body: String = "",
        pinState: PinState = .unpinned,
        editingDraft: String? = nil,
        libraryBodies: [String] = [],
        showsCharacterDetails: Bool = false,
        feedback: String? = nil,
        deleting: Bool = false,
        reduceMotion: Bool? = nil
    ) -> some View {
        let fixture = makeFeature(
            body: body,
            pinState: pinState,
            editingDraft: editingDraft,
            libraryBodies: libraryBodies,
            showsCharacterDetails: showsCharacterDetails,
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
        return AppSheetPreviewHost {
            AppSheetContainer(title: "Note Library", close: {}) {
                NoteLibraryView(
                    feature: fixture.feature,
                    timestampFormatter: previewTimestampFormatter
                )
            }
        }
        .modelContainer(fixture.container)
    }

    static func settings(mode: AppearanceMode) -> some View {
        return AppSheetPreviewHost {
            AppSheetContainer(title: "Settings", close: {}) {
                SettingsView(appearance: AppearanceSettings(previewMode: mode))
            }
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
        editingDraft: String? = nil,
        libraryBodies: [String] = [],
        showsCharacterDetails: Bool = false,
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
            editingDraft: editingDraft,
            isCharacterCountVisible: showsCharacterDetails,
            deleteConfirmation: deleting
                ? .pending(
                    message: "This note will be permanently deleted. This action cannot be undone."
                )
                : nil,
            feedbackMessage: feedback
        )
        return (feature, container)
    }

    private static var previewTimestampFormatter: LibraryTimestampFormatter {
        var calendar = Calendar(identifier: .gregorian)
        let locale = Locale(identifier: "en_US_POSIX")
        let timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = locale
        calendar.timeZone = timeZone

        return LibraryTimestampFormatter(
            calendar: calendar,
            locale: locale,
            timeZone: timeZone,
            now: { Date(timeIntervalSinceReferenceDate: 800_000_000) }
        )
    }
}

#Preview("Workbench · Empty Light") {
    PreviewFixtures.workbench()
        .preferredColorScheme(.light)
}

#Preview("Workbench · Empty Dark") {
    PreviewFixtures.workbench()
        .preferredColorScheme(.dark)
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

#Preview("Note Library Sheet · Dark") {
    PreviewFixtures.library(
        libraryBodies: ["Call home before boarding", "Review the launch notes"]
    )
    .preferredColorScheme(.dark)
}

#Preview("Settings · Automatic · Light Environment") {
    PreviewFixtures.settings(mode: .automatic)
        .preferredColorScheme(.light)
}

#Preview("Settings · Automatic · Dark Environment") {
    PreviewFixtures.settings(mode: .automatic)
        .preferredColorScheme(.dark)
}

#Preview("Settings · Light Selected") {
    PreviewFixtures.settings(mode: .light)
        .preferredColorScheme(.light)
}

#Preview("Settings · Dark Selected") {
    PreviewFixtures.settings(mode: .dark)
        .preferredColorScheme(.dark)
}

#Preview("Workbench · Short Note") {
    PreviewFixtures.workbench(body: "Call home before boarding.")
}

#Preview("Workbench · Multilingual and Emoji") {
    PreviewFixtures.workbench(body: "Ship the tiny thing.\n然后去散步 🌿👨‍👩‍👧‍👦")
}

#Preview("Workbench · Rendered Bullets") {
    PreviewFixtures.workbench(
        body: "Plain source line\n- Rendered bullet\n# Literal heading"
    )
}

#Preview("Workbench · Editing Source Light") {
    PreviewFixtures.workbench(
        body: "Saved source\n- Saved bullet",
        editingDraft: "Editing source\n- Draft bullet"
    )
    .preferredColorScheme(.light)
}

#Preview("Workbench · Editing Source Dark") {
    PreviewFixtures.workbench(
        body: "Saved source\n- Saved bullet",
        editingDraft: "Editing source\n- Draft bullet"
    )
    .preferredColorScheme(.dark)
}

#Preview("Workbench · 239 Characters") {
    PreviewFixtures.workbench(body: String(repeating: "字", count: 239))
}

#Preview("Workbench · Character Limit Light") {
    PreviewFixtures.workbench(
        body: String(repeating: "界", count: 240),
        showsCharacterDetails: true
    )
    .preferredColorScheme(.light)
}

#Preview("Workbench · Character Limit Dark") {
    PreviewFixtures.workbench(
        body: String(repeating: "界", count: 240),
        showsCharacterDetails: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Workbench · Editing at 240 Light") {
    PreviewFixtures.workbench(
        body: "Saved value remains unchanged",
        editingDraft: String(repeating: "界", count: 240),
        showsCharacterDetails: true
    )
    .preferredColorScheme(.light)
}

#Preview("Workbench · Editing at 240 Dark") {
    PreviewFixtures.workbench(
        body: "Saved value remains unchanged",
        editingDraft: String(repeating: "界", count: 240),
        showsCharacterDetails: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Workbench · Save Error Light") {
    PreviewFixtures.workbench(
        body: "Last committed source",
        editingDraft: "Unsaved draft stays in the editor",
        feedback: "Your note hasn't been saved."
    )
    .preferredColorScheme(.light)
}

#Preview("Workbench · Save Error Dark") {
    PreviewFixtures.workbench(
        body: "Last committed source",
        editingDraft: "Unsaved draft stays in the editor",
        feedback: "Your note hasn't been saved."
    )
    .preferredColorScheme(.dark)
}

#Preview("Workbench · Live Light") {
    PreviewFixtures.workbench(body: "This note is currently Live.", pinState: .pinned)
        .preferredColorScheme(.light)
}

#Preview("Workbench · Live Dark") {
    PreviewFixtures.workbench(body: "This note is currently Live.", pinState: .pinned)
        .preferredColorScheme(.dark)
}

#Preview("Workbench · Live Error Light") {
    PreviewFixtures.workbench(
        body: "This note is saved on this device.",
        pinState: .pinned,
        feedback: "Live may not be up to date."
    )
    .preferredColorScheme(.light)
}

#Preview("Workbench · Live Error Dark") {
    PreviewFixtures.workbench(
        body: "This note is saved on this device.",
        pinState: .pinned,
        feedback: "Live may not be up to date."
    )
    .preferredColorScheme(.dark)
}

#Preview("Workbench · Delete Confirmation Light") {
    PreviewFixtures.workbench(body: "A note ready to delete", deleting: true)
        .preferredColorScheme(.light)
}

#Preview("Workbench · Delete Confirmation Dark") {
    PreviewFixtures.workbench(body: "A note ready to delete", deleting: true)
        .preferredColorScheme(.dark)
}

#Preview("Workbench · Maximum Dynamic Type Light") {
    PreviewFixtures.workbench(body: "All actions remain reachable at the largest text size.")
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.light)
}

#Preview("Workbench · Maximum Dynamic Type Dark") {
    PreviewFixtures.workbench(body: "All actions remain reachable at the largest text size.")
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}

#Preview("Workbench · Reduce Motion Light") {
    PreviewFixtures.workbench(
        body: "State is never communicated through motion alone.",
        pinState: .pinned,
        reduceMotion: true
    )
    .preferredColorScheme(.light)
}

#Preview("Workbench · Reduce Motion Dark") {
    PreviewFixtures.workbench(
        body: "State is never communicated through motion alone.",
        pinState: .pinned,
        reduceMotion: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Note Library · Empty Light") {
    PreviewFixtures.library(libraryBodies: [])
        .preferredColorScheme(.light)
}

#Preview("Note Library · Empty Dark") {
    PreviewFixtures.library(libraryBodies: [])
        .preferredColorScheme(.dark)
}
#endif
