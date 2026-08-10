#if DEBUG
import SwiftUI

private struct WorkbenchActionDockPreview: View {
    let model: WorkbenchActionDockModel

    var body: some View {
        WorkbenchActionDock(model: model, move: {}, toggleLive: {}, delete: {})
            .background(IslandDesign.Colors.workbenchCanvas)
    }
}

private extension WorkbenchActionDockModel {
    static func preview(
        content: WorkbenchActionAvailability = .enabled,
        live: WorkbenchActionAvailability = .enabled,
        pinState: PinState = .unpinned,
        transition: LiveActionTransition? = nil
    ) -> WorkbenchActionDockModel {
        make(
            contentAvailability: content,
            liveAvailability: live,
            pinState: pinState,
            transition: transition
        )
    }
}

#Preview("Dock · Empty · Light") {
    WorkbenchActionDockPreview(
        model: .preview(content: .needsContent, live: .needsContent)
    )
    .preferredColorScheme(.light)
}

#Preview("Dock · Empty · Dark") {
    WorkbenchActionDockPreview(
        model: .preview(content: .needsContent, live: .needsContent)
    )
    .preferredColorScheme(.dark)
}

#Preview("Dock · Ready · Light") {
    WorkbenchActionDockPreview(model: .preview())
        .preferredColorScheme(.light)
}

#Preview("Dock · Ready · Dark") {
    WorkbenchActionDockPreview(model: .preview())
        .preferredColorScheme(.dark)
}

#Preview("Dock · Live · Light") {
    WorkbenchActionDockPreview(model: .preview(pinState: .pinned))
        .preferredColorScheme(.light)
}

#Preview("Dock · Live · Dark") {
    WorkbenchActionDockPreview(model: .preview(pinState: .pinned))
        .preferredColorScheme(.dark)
}

#Preview("Dock · Starting") {
    WorkbenchActionDockPreview(
        model: .preview(content: .busy, live: .busy, transition: .starting)
    )
}

#Preview("Dock · Stopping") {
    WorkbenchActionDockPreview(
        model: .preview(
            content: .busy,
            live: .busy,
            pinState: .pinned,
            transition: .stopping
        )
    )
}

#Preview("Dock · Busy Move") {
    WorkbenchActionDockPreview(
        model: WorkbenchActionDockModel(
            move: DockActionState(availability: .busy),
            live: LiveActionControlModel(state: .ready, availability: .enabled),
            delete: DockActionState(availability: .enabled)
        )
    )
}

#Preview("Dock · Busy Delete") {
    WorkbenchActionDockPreview(
        model: WorkbenchActionDockModel(
            move: DockActionState(availability: .enabled),
            live: LiveActionControlModel(state: .ready, availability: .enabled),
            delete: DockActionState(availability: .busy)
        )
    )
}

#Preview("Dock · Accessibility XXXL") {
    WorkbenchActionDockPreview(model: .preview())
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Dock · Narrow Width", traits: .fixedLayout(width: 320, height: 160)) {
    WorkbenchActionDockPreview(model: .preview())
}
#endif
