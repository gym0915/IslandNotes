import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var feature: IslandNotesFeature
    @State private var showsLibrary = false
    private let initialDeepLink: URL?

    init(
        modelContext: ModelContext,
        liveActivityController: LiveActivityControlling,
        initialDeepLink: URL? = nil
    ) {
        self.initialDeepLink = initialDeepLink
        _feature = State(
            initialValue: IslandNotesFeature(
                modelContext: modelContext,
                liveActivityController: liveActivityController
            )
        )
    }

    var body: some View {
        NavigationStack {
            WorkbenchView(feature: feature) {
                showsLibrary = true
            }
            .navigationDestination(isPresented: $showsLibrary) {
                NoteLibraryView(feature: feature)
            }
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
    }

    private func handleDeepLink(_ url: URL) {
        guard DeepLinkRouter.destination(for: url) == .workbench else { return }
        showsLibrary = false
        Task { await feature.reconcileActivities() }
    }
}
