#if DEBUG
import Foundation

enum LiveActivityControllerSelection: Equatable {
    case system
    case deterministicUITest

    static func mode(arguments: [String]) -> Self {
        arguments.contains("--uitesting-fake-live-activity")
            ? .deterministicUITest
            : .system
    }
}

@MainActor
final class DeterministicUITestLiveActivityController: LiveActivityControlling {
    private var activeActivities: [ActivitySession] = []

    func activities() async -> [ActivitySession] {
        activeActivities
    }

    func request(noteID: UUID, body: String, version: Int) async throws {
        activeActivities = [
            ActivitySession(
                activityID: "ui-testing-live-activity",
                noteID: noteID,
                body: body,
                version: version,
                isActive: true
            )
        ]
    }

    func update(activityID: String, body: String, version: Int) async throws {
        guard let index = activeActivities.firstIndex(where: { $0.activityID == activityID }) else {
            return
        }
        let previous = activeActivities[index]
        activeActivities[index] = ActivitySession(
            activityID: previous.activityID,
            noteID: previous.noteID,
            body: body,
            version: version,
            isActive: previous.isActive
        )
    }

    func end(activityID: String) async throws {
        activeActivities.removeAll { $0.activityID == activityID }
    }
}
#endif
