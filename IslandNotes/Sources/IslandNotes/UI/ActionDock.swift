import SwiftUI

struct ActionDock: View {
    @Bindable var feature: IslandNotesFeature

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: IslandDesign.Spacing.x4) {
                compactIconAction(moveAction)

                Spacer(minLength: IslandDesign.Spacing.x2)
                liveAction
                Spacer(minLength: IslandDesign.Spacing.x2)

                compactIconAction(deleteAction)
            }

            VStack(spacing: IslandDesign.Spacing.x2) {
                expandedAction(moveAction)
                liveAction
                expandedAction(deleteAction)
            }
        }
    }

    private var moveAction: DockAction {
        DockAction(
            title: "Move to Note Library",
            icon: .moveToLibrary,
            identifier: "archive-current-note",
            semantic: .move,
            isEnabled: feature.canArchive,
            perform: { Task { try? await feature.archiveCurrentNote() } }
        )
    }

    private var deleteAction: DockAction {
        DockAction(
            title: "Delete Note",
            icon: .delete,
            identifier: "delete-current-note",
            semantic: .delete,
            isEnabled: feature.canDelete,
            perform: feature.requestDelete
        )
    }

    private var liveAction: some View {
        Button {
            Task {
                if feature.pinState == .pinned {
                    await feature.cancelPinning()
                } else {
                    await feature.startPinning()
                }
            }
        } label: {
            if feature.pinState == .pinned {
                Text("Live")
            } else {
                HStack(spacing: IslandDesign.Spacing.x2) {
                    AppIconView(icon: .live, size: IslandDesign.Sizing.smallIcon)
                    Text("Go Live")
                }
            }
        }
        .buttonStyle(IslandButtonStyle(kind: liveSemantic.kind))
        .disabled(!feature.canTogglePin)
        .accessibilityIdentifier("toggle-pin")
        .accessibilityLabel(feature.pinState == .pinned ? "Live" : "Go Live")
        .accessibilityHint(
            feature.pinState == .pinned
                ? "Stops showing the current note on system surfaces"
                : disabledActionHint(isEnabled: feature.canPin)
        )
    }

    private func compactIconAction(_ action: DockAction) -> some View {
        IslandIconButton(
            icon: action.icon,
            label: action.title,
            kind: action.semantic.kind,
            role: action.semantic.role,
            action: action.perform
        )
        .disabled(!action.isEnabled)
        .accessibilityIdentifier(action.identifier)
        .accessibilityHint(disabledActionHint(isEnabled: action.isEnabled))
    }

    private func expandedAction(_ action: DockAction) -> some View {
        Button(role: action.semantic.role, action: action.perform) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                AppIconView(icon: action.icon, size: IslandDesign.Sizing.smallIcon)
                Text(action.title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(IslandButtonStyle(kind: action.semantic.kind))
        .disabled(!action.isEnabled)
        .accessibilityIdentifier(action.identifier)
        .accessibilityHint(disabledActionHint(isEnabled: action.isEnabled))
    }

    private func disabledActionHint(isEnabled: Bool) -> String {
        isEnabled ? "" : "The current note needs non-whitespace text"
    }

    private var liveSemantic: WorkbenchActionSemantic {
        feature.pinState == .pinned ? .live : .goLive
    }
}

private struct DockAction {
    let title: String
    let icon: AppIcon
    let identifier: String
    let semantic: WorkbenchActionSemantic
    let isEnabled: Bool
    let perform: () -> Void
}

enum WorkbenchActionSemantic: Equatable {
    case move
    case goLive
    case live
    case delete

    var kind: IslandActionKind {
        switch self {
        case .move, .goLive: .neutral
        case .live: .live
        case .delete: .destructive
        }
    }

    var role: ButtonRole? {
        self == .delete ? .destructive : nil
    }
}
