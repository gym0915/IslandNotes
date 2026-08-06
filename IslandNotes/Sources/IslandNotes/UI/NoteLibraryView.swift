import SwiftUI

struct NoteLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var feature: IslandNotesFeature

    var body: some View {
        Group {
            if feature.library.isEmpty {
                VStack(spacing: IslandDesign.Spacing.x4) {
                    AppIconView(icon: .noteLibrary, size: IslandDesign.Sizing.largeIcon)
                        .foregroundStyle(IslandDesign.Colors.secondaryText)
                    Text("No notes yet")
                        .font(IslandDesign.Typography.sheetTitle)
                    Text("Move your current note here to keep it for later.")
                        .font(IslandDesign.Typography.body)
                        .foregroundStyle(IslandDesign.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(IslandDesign.Spacing.x8)
                .accessibilityIdentifier("empty-library")
            } else {
                List(feature.library) { note in
                    Button {
                        Task {
                            try? await feature.selectLibraryNote(id: note.id)
                            if feature.currentNote?.id == note.id { dismiss() }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: IslandDesign.Spacing.x2) {
                            Text(note.body)
                                .font(IslandDesign.Typography.body)
                                .foregroundStyle(IslandDesign.Colors.primaryText)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            if let archivedAt = note.archivedAt {
                                Text(archivedAt, format: .dateTime.month().day().hour().minute())
                                    .font(IslandDesign.Typography.caption)
                                    .foregroundStyle(IslandDesign.Colors.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, IslandDesign.Spacing.x2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("library-note-\(note.id.uuidString)")
                    .accessibilityLabel("Note: \(note.body)")
                    .accessibilityHint("Replaces the current note")
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}
