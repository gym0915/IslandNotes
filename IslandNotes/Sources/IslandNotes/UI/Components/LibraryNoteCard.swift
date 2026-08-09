import SwiftUI

struct LibraryNoteCard: View {
    let note: NoteSnapshot
    let timestamp: String
    let replacementEnabled: Bool
    let replacementHint: String
    let replace: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: IslandDesign.Spacing.x4) {
            VStack(alignment: .leading, spacing: IslandDesign.Spacing.x4) {
                Text(note.body)
                    .font(IslandDesign.Typography.body)
                    .foregroundStyle(IslandDesign.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(timestamp)
                    .font(IslandDesign.Typography.metadata)
                    .foregroundStyle(IslandDesign.Colors.secondaryText)
            }

            IslandIconButton(icon: .replace, label: "Replace current note", action: replace)
                .disabled(!replacementEnabled)
                .accessibilityHint(replacementHint)
        }
        .padding(IslandDesign.Spacing.x4)
    }
}
