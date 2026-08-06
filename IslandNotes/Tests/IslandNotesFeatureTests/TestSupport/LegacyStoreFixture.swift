import Foundation

enum LegacyStoreFixture {
    static let currentNoteID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let libraryNoteIDs = [
        UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
    ]

    @MainActor
    static func copy() throws -> LegacyStoreCopy {
        let bundle = Bundle(for: LegacyStoreFixtureBundleToken.self)
        guard let sourceStore = bundle.url(
            forResource: "LegacyStoreV1",
            withExtension: "store"
        ) else {
            throw LegacyStoreFixtureError.missingBundledStore
        }

        let storeDirectory = FileManager.default.temporaryDirectory
            .appending(path: "IslandNotesLegacyStore-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        let destinationStore = storeDirectory.appending(path: "LegacyStoreV1.store")
        try FileManager.default.copyItem(at: sourceStore, to: destinationStore)

        return LegacyStoreCopy(storeURL: destinationStore)
    }
}

final class LegacyStoreCopy {
    let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    @MainActor
    func makeHarness(allowsSave: Bool = true) throws -> FeatureHarness {
        try FeatureHarness.make(
            storeURL: storeURL,
            allowsSave: allowsSave
        )
    }
}

private final class LegacyStoreFixtureBundleToken: NSObject {}

private enum LegacyStoreFixtureError: Error {
    case missingBundledStore
}
