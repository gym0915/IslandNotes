import Foundation

@MainActor
protocol LiveActivityControlling: AnyObject {
    func activities() async -> [ActivitySession]
    func request(noteID: UUID, body: String, version: Int) async throws
    func update(activityID: String, body: String, version: Int) async throws
    func end(activityID: String) async throws
}
