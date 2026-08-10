import SwiftUI

struct EditingCommitBar: View {
    let isEnabled: Bool
    let accessibilityValue: String
    let accessibilityHint: String
    let commit: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: commit) {
            Text("Done")
                .frame(maxWidth: .infinity)
        }
            .buttonStyle(IslandButtonStyle(kind: .primary))
            .frame(maxWidth: .infinity)
            .disabled(!isEnabled)
            .accessibilityIdentifier("done-editing")
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(IslandDesign.Colors.workbenchCanvas)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("editing-commit-bar")
    }

    private var horizontalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Spacing.x4
            : IslandDesign.Spacing.x6
    }

    private var verticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Spacing.x2
            : IslandDesign.Spacing.x4
    }
}

#Preview("Editing Commit Bar · Light") {
    EditingCommitBar(
        isEnabled: true,
        accessibilityValue: "",
        accessibilityHint: "",
        commit: {}
    )
    .background(IslandDesign.Colors.workbenchCanvas)
    .preferredColorScheme(.light)
}

#Preview("Editing Commit Bar · Dark") {
    EditingCommitBar(
        isEnabled: true,
        accessibilityValue: "",
        accessibilityHint: "",
        commit: {}
    )
    .background(IslandDesign.Colors.workbenchCanvas)
    .preferredColorScheme(.dark)
}
