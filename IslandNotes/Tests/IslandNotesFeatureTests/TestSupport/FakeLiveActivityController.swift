import Foundation
@testable import IslandNotes

enum FakeLiveActivityError: Error {
    case requestFailed
    case updateFailed
    case endFailed
}

enum FakeEndOutcome {
    case remove
    case removeThenThrow
    case keepThenThrow
}

@MainActor
final class FakeLiveActivityController: LiveActivityControlling {
    private(set) var activeActivities: [ActivitySession] = []
    var requestFailure: Error?
    var updateFailure: Error?
    var endOutcome: FakeEndOutcome = .remove

    func seedActivities(_ activities: [ActivitySession]) {
        activeActivities = activities
    }

    func activities() async -> [ActivitySession] {
        activeActivities
    }

    func request(noteID: UUID, body: String, version: Int) async throws {
        if let requestFailure {
            throw requestFailure
        }
        activeActivities = [
            ActivitySession(
                activityID: UUID().uuidString,
                noteID: noteID,
                body: body,
                version: version,
                isActive: true
            )
        ]
    }

    func update(activityID: String, body: String, version: Int) async throws {
        if let updateFailure {
            throw updateFailure
        }
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
        switch endOutcome {
        case .remove:
            activeActivities.removeAll { $0.activityID == activityID }
        case .removeThenThrow:
            activeActivities.removeAll { $0.activityID == activityID }
            throw FakeLiveActivityError.endFailed
        case .keepThenThrow:
            throw FakeLiveActivityError.endFailed
        }
    }
}
