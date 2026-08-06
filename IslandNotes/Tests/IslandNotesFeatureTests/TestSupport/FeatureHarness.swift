import Foundation
import SwiftData
@testable import IslandNotes

@MainActor
final class FeatureHarness {
    let container: ModelContainer
    let context: ModelContext
    let controller: FakeLiveActivityController
    let feature: IslandNotesFeature

    private init(
        container: ModelContainer,
        context: ModelContext,
        controller: FakeLiveActivityController,
        feature: IslandNotesFeature
    ) {
        self.container = container
        self.context = context
        self.controller = controller
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
        let feature = IslandNotesFeature(
            modelContext: context,
            liveActivityController: controller,
            now: clock
        )
        return FeatureHarness(
            container: container,
            context: context,
            controller: controller,
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
        let feature = IslandNotesFeature(
            modelContext: context,
            liveActivityController: controller,
            now: { Date(timeIntervalSince1970: 9_000) }
        )
        return FeatureHarness(
            container: container,
            context: context,
            controller: controller,
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
