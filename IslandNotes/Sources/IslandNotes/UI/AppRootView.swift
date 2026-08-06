import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var feature: IslandNotesFeature
    @State private var router = AppRouter()
    private let initialDeepLink: URL?

    init(
        modelContext: ModelContext,
        liveActivityController: LiveActivityControlling,
        initialDeepLink: URL? = nil
    ) {
        self.initialDeepLink = initialDeepLink
        let workspace = NoteWorkspace(modelContext: modelContext)
        _feature = State(
            initialValue: IslandNotesFeature(
                workspace: workspace,
                liveActivityController: liveActivityController
            )
        )
    }

    var body: some View {
        NavigationStack {
            WorkbenchView(
                feature: feature,
                openNoteLibrary: router.presentNoteLibrary,
                openSettings: router.presentSettings
            )
        }
        .task {
            try? await feature.bootstrap()
            if let initialDeepLink {
                handleDeepLink(initialDeepLink)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await feature.reconcileActivities() }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .sheet(
            item: Binding(
                get: { router.presentedSheet },
                set: { destination in
                    if destination == nil { router.dismissSheet() }
                }
            ),
            onDismiss: router.dismissSheet
        ) { destination in
            sheet(for: destination)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(IslandDesign.Radius.sheet)
                .presentationBackground(IslandDesign.Colors.canvas)
        }
    }

    @ViewBuilder
    private func sheet(for destination: AppSheet) -> some View {
        switch destination {
        case .noteLibrary:
            AppSheetContainer(title: "Note Library", close: router.dismissSheet) {
                NoteLibraryView(feature: feature)
            }
        case .settings:
            AppSheetContainer(title: "Settings", close: router.dismissSheet) {
                SettingsView()
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard router.handleDeepLink(url) else { return }
        Task { await feature.reconcileActivities() }
    }
}
