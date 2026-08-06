import Foundation
import SwiftData
@testable import IslandNotes

@MainActor
final class FeatureHarness {
    let container: ModelContainer
    let context: ModelContext
    let controller: FakeLiveActivityController
    let workspace: NoteWorkspace
    let feature: IslandNotesFeature

    private init(
        container: ModelContainer,
        context: ModelContext,
        controller: FakeLiveActivityController,
        workspace: NoteWorkspace,
        feature: IslandNotesFeature
    ) {
        self.container = container
        self.context = context
        self.controller = controller
        self.workspace = workspace
        self.feature = feature
    }

    static func make(now: Date = Date(timeIntervalSince1970: 1_000)) throws -> FeatureHarness {
        try make(clock: { now })
    }

    static func make(clock: @escaping () -> Date) throws -> FeatureHarness {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: NoteRecord.self,
            WorkbenchRecord.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let controller = FakeLiveActivityController()
        let workspace = NoteWorkspace(modelContext: context, now: clock)
        let feature = IslandNotesFeature(
            workspace: workspace,
            liveActivityController: controller
        )
        return FeatureHarness(
            container: container,
            context: context,
            controller: controller,
            workspace: workspace,
            feature: feature
        )
    }

    static func make(
        storeURL: URL,
        allowsSave: Bool
    ) throws -> FeatureHarness {
        let configuration = ModelConfiguration(
            url: storeURL,
            allowsSave: allowsSave
        )
        let container = try ModelContainer(
            for: NoteRecord.self,
            WorkbenchRecord.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let controller = FakeLiveActivityController()
        let workspace = NoteWorkspace(
            modelContext: context,
            now: { Date(timeIntervalSince1970: 9_000) }
        )
        let feature = IslandNotesFeature(
            workspace: workspace,
            liveActivityController: controller
        )
        return FeatureHarness(
            container: container,
            context: context,
            controller: controller,
            workspace: workspace,
            feature: feature
        )
    }

    func notes() throws -> [NoteRecord] {
        try context.fetch(FetchDescriptor<NoteRecord>())
    }

    func workbenches() throws -> [WorkbenchRecord] {
        try context.fetch(FetchDescriptor<WorkbenchRecord>())
    }

    func commitCurrentNote(_ text: String) throws {
        feature.stageEditorText(
            proposedText: text,
            markedTextActive: false
        )
        try feature.completeEditing()
    }
}
