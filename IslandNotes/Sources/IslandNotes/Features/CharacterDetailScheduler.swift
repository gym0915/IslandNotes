import Foundation

@MainActor
struct CharacterDetailCancellation {
    private let cancellation: @MainActor () -> Void

    init(_ cancellation: @escaping @MainActor () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        cancellation()
    }
}

@MainActor
struct CharacterDetailScheduler {
    let schedule: (@escaping @MainActor () -> Void) -> CharacterDetailCancellation

    static var live: CharacterDetailScheduler {
        CharacterDetailScheduler { action in
            let task = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                action()
            }
            return CharacterDetailCancellation {
                task.cancel()
            }
        }
    }
}
