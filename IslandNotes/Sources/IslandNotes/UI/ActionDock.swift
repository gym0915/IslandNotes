import SwiftUI

enum LiveActionState: Equatable, Sendable {
    case unavailable
    case ready
    case starting
    case live
    case stopping
}

enum LiveActionTransition: Equatable, Sendable {
    case starting
    case stopping
}

struct DockActionState: Equatable, Sendable {
    let availability: WorkbenchActionAvailability

    var isEnabled: Bool { availability.isEnabled }
    var isBusy: Bool { availability == .busy }
    var accessibilityHint: String { availability.accessibilityHint }
}

struct LiveActionControlModel: Equatable, Sendable {
    let state: LiveActionState
    let availability: WorkbenchActionAvailability

    var label: String {
        switch state {
        case .unavailable, .ready, .starting:
            "Go Live"
        case .live, .stopping:
            "Live"
        }
    }

    var accessibilityValue: String {
        switch state {
        case .starting:
            "Starting"
        case .live:
            "Live"
        case .stopping:
            "Stopping"
        case .unavailable, .ready:
            ""
        }
    }

    var accessibilityHint: String {
        guard availability.isEnabled else { return availability.accessibilityHint }
        return state == .live
            ? "Stops showing the current note on system surfaces"
            : ""
    }

    var isEnabled: Bool {
        availability.isEnabled && (state == .ready || state == .live)
    }
}

struct WorkbenchActionDockModel: Equatable, Sendable {
    let move: DockActionState
    let live: LiveActionControlModel
    let delete: DockActionState

    static func make(
        contentAvailability: WorkbenchActionAvailability,
        liveAvailability: WorkbenchActionAvailability,
        pinState: PinState,
        transition: LiveActionTransition?
    ) -> WorkbenchActionDockModel {
        let liveState: LiveActionState
        if let transition {
            liveState = transition == .starting ? .starting : .stopping
        } else if pinState == .pinned {
            liveState = .live
        } else if liveAvailability.isEnabled {
            liveState = .ready
        } else {
            liveState = .unavailable
        }

        return WorkbenchActionDockModel(
            move: DockActionState(availability: contentAvailability),
            live: LiveActionControlModel(
                state: liveState,
                availability: liveAvailability
            ),
            delete: DockActionState(availability: contentAvailability)
        )
    }

    var orderedAccessibilityLabels: [String] {
        ["Move to Note Library", live.label, "Delete Note"]
    }
}

struct WorkbenchActionDock: View {
    let model: WorkbenchActionDockModel
    var reduceMotionOverride: Bool? = nil
    let move: () -> Void
    let toggleLive: () -> Void
    let delete: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        IslandGlassEffectGroup(spacing: preferredSpacing) {
            ViewThatFits(in: .horizontal) {
                dockRow(
                    spacing: preferredSpacing,
                    liveWidth: IslandDesign.Sizing.liveActionWidth
                )
                .padding(.horizontal, preferredHorizontalPadding)

                dockRow(
                    spacing: IslandDesign.Spacing.x2,
                    liveWidth: IslandDesign.Sizing.compactLiveActionWidth
                )
                .padding(.horizontal, IslandDesign.Spacing.x4)
            }
        }
        .padding(.bottom, preferredBottomPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workbench-action-dock")
    }

    private var preferredHorizontalPadding: CGFloat {
        let surfacePadding = dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Spacing.x4
            : IslandDesign.Spacing.x6
        return surfacePadding + IslandDesign.Workbench.dockOuterControlInset
    }

    private var preferredSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Spacing.x2
            : IslandDesign.Spacing.x4
    }

    private var preferredBottomPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Spacing.x4
            : IslandDesign.Spacing.x6
    }

    private var liveControlHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Sizing.accessibilityActionHeight
            : IslandDesign.Sizing.dockActionHeight
    }

    private func dockRow(spacing: CGFloat, liveWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            DockIconAction(
                icon: .moveToLibrary,
                label: "Move to Note Library",
                identifier: "archive-current-note",
                state: model.move,
                action: move
            )
            .accessibilitySortPriority(3)

            Spacer(minLength: spacing)

            LiveActionControl(
                model: model.live,
                width: liveWidth,
                height: liveControlHeight,
                compactContent: spacing == IslandDesign.Spacing.x2,
                reduceMotionOverride: reduceMotionOverride,
                action: toggleLive
            )
            .accessibilitySortPriority(2)

            Spacer(minLength: spacing)

            DockIconAction(
                icon: .delete,
                label: "Delete Note",
                identifier: "delete-current-note",
                state: model.delete,
                action: delete
            )
            .accessibilitySortPriority(1)
        }
        .frame(maxWidth: .infinity)
    }
}
