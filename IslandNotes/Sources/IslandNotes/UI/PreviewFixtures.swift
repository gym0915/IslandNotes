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
                openLibrary: {}
            )
        }
        .modelContainer(fixture.container)
    }

    static func library(libraryBodies: [String]) -> some View {
        let fixture = makeFeature(body: "", libraryBodies: libraryBodies)
        return NavigationStack {
            NoteLibraryView(feature: fixture.feature)
        }
        .modelContainer(fixture.container)
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
            deleteConfirmation: deleting ? .pending(message: "删除后无法恢复") : nil,
            feedbackMessage: feedback
        )
        return (feature, container)
    }
}

#Preview("工作台 · 首次空白") {
    PreviewFixtures.workbench()
}

#Preview("工作台 · 有效短文") {
    PreviewFixtures.workbench(body: "登机前记得给家里打电话。")
}

#Preview("工作台 · 中英换行与 Emoji") {
    PreviewFixtures.workbench(body: "Ship the tiny thing.\n然后去散步 🌿👨‍👩‍👧‍👦")
}

#Preview("工作台 · 239 字") {
    PreviewFixtures.workbench(body: String(repeating: "字", count: 239))
}

#Preview("工作台 · 240 字") {
    PreviewFixtures.workbench(body: String(repeating: "A", count: 240))
}

#Preview("工作台 · 超限反馈") {
    PreviewFixtures.workbench(
        body: String(repeating: "界", count: 240),
        reachedLimit: true
    )
}

#Preview("工作台 · 挂起中") {
    PreviewFixtures.workbench(body: "这是岛上正在展示的便签。", pinState: .pinned)
}

#Preview("工作台 · 更新未同步") {
    PreviewFixtures.workbench(
        body: "本机内容已经保存。",
        pinState: .pinned,
        feedback: "系统展示可能尚未同步"
    )
}

#Preview("工作台 · 删除确认") {
    PreviewFixtures.workbench(body: "即将删除的便签", deleting: true)
}

#Preview("工作台 · 深色") {
    PreviewFixtures.workbench(body: "跟随系统深色外观。")
        .preferredColorScheme(.dark)
}

#Preview("工作台 · 最大动态字体") {
    PreviewFixtures.workbench(body: "最大字号仍然可以滚动到所有动作。")
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("工作台 · 减少动态效果") {
    PreviewFixtures.workbench(
        body: "状态不依赖动画表达。",
        pinState: .pinned,
        reduceMotion: true
    )
}

#Preview("便签库 · 空") {
    PreviewFixtures.library(libraryBodies: [])
}

#Preview("便签库 · 多条倒序") {
    PreviewFixtures.library(
        libraryBodies: [
            "最近放入的便签\n保留换行与原文语义",
            "Second note with an emoji 🧭",
            "更早的一条便签",
        ]
    )
}
#endif
