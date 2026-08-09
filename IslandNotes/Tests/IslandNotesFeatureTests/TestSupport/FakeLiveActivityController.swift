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
    private(set) var activitiesCallCount = 0
    private(set) var requestCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var endCallCount = 0
    var requestFailure: Error?
    var updateFailure: Error?
    var endOutcome: FakeEndOutcome = .remove
    private var pausesNextActivitiesCall = false
    private var activitiesContinuation: CheckedContinuation<Void, Never>?
    private var pausesRequests = false
    private var requestContinuations: [CheckedContinuation<Void, Never>] = []
    private var pausesUpdates = false
    private var updateContinuations: [CheckedContinuation<Void, Never>] = []
    private var pausesEnds = false
    private var endContinuations: [CheckedContinuation<Void, Never>] = []

    var hasPausedActivitiesCall: Bool {
        activitiesContinuation != nil
    }

    var hasPausedRequest: Bool {
        !requestContinuations.isEmpty
    }

    var hasPausedUpdate: Bool {
        !updateContinuations.isEmpty
    }

    func seedActivities(_ activities: [ActivitySession]) {
        activeActivities = activities
    }

    func activities() async -> [ActivitySession] {
        activitiesCallCount += 1
        if pausesNextActivitiesCall {
            pausesNextActivitiesCall = false
            await withCheckedContinuation { continuation in
                activitiesContinuation = continuation
            }
        }
        return activeActivities
    }

    func request(noteID: UUID, body: String, version: Int) async throws {
        requestCallCount += 1
        if pausesRequests {
            await withCheckedContinuation { continuation in
                requestContinuations.append(continuation)
            }
        }
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
        updateCallCount += 1
        if pausesUpdates {
            await withCheckedContinuation { continuation in
                updateContinuations.append(continuation)
            }
        }
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
        endCallCount += 1
        if pausesEnds {
            await withCheckedContinuation { continuation in
                endContinuations.append(continuation)
            }
        }
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

    func pauseNextActivities() {
        pausesNextActivitiesCall = true
    }

    func resumeActivities() {
        let continuation = activitiesContinuation
        activitiesContinuation = nil
        continuation?.resume()
    }

    func pauseRequests() {
        pausesRequests = true
    }

    func resumeRequests() {
        pausesRequests = false
        let continuations = requestContinuations
        requestContinuations.removeAll()
        continuations.forEach { $0.resume() }
    }

    func pauseUpdates() {
        pausesUpdates = true
    }

    func resumeUpdates() {
        pausesUpdates = false
        let continuations = updateContinuations
        updateContinuations.removeAll()
        continuations.forEach { $0.resume() }
    }

    func pauseEnds() {
        pausesEnds = true
    }

    func resumeEnds() {
        pausesEnds = false
        let continuations = endContinuations
        endContinuations.removeAll()
        continuations.forEach { $0.resume() }
    }
}
