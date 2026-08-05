@preconcurrency import ActivityKit
import Foundation

@MainActor
final class ActivityKitLiveActivityController: LiveActivityControlling {
    func activities() async -> [ActivitySession] {
        Activity<IslandNoteActivityAttributes>.activities.map { activity in
            ActivitySession(
                activityID: activity.id,
                noteID: activity.attributes.noteID,
                body: activity.content.state.body,
                version: activity.content.state.version,
                isActive: Self.isActive(activity.activityState)
            )
        }
    }

    func request(noteID: UUID, body: String, version: Int) async throws {
        let attributes = IslandNoteActivityAttributes(noteID: noteID)
        let state = IslandNoteActivityAttributes.ContentState(body: body, version: version)
        let content = ActivityContent(state: state, staleDate: nil)
        _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    func update(activityID: String, body: String, version: Int) async throws {
        guard let activity = Activity<IslandNoteActivityAttributes>.activities
            .first(where: { $0.id == activityID }) else { return }
        let state = IslandNoteActivityAttributes.ContentState(body: body, version: version)
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end(activityID: String) async throws {
        guard let activity = Activity<IslandNoteActivityAttributes>.activities
            .first(where: { $0.id == activityID }) else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    private static func isActive(_ state: ActivityState) -> Bool {
        switch state {
        case .active, .stale:
            true
        case .pending, .ended, .dismissed:
            false
        @unknown default:
            false
        }
    }
}
