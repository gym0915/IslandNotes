import SwiftUI

struct NoteLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var feature: IslandNotesFeature

    var body: some View {
        Group {
            if feature.library.isEmpty {
                VStack(spacing: IslandDesign.Spacing.x4) {
                    AppIconView(icon: .noteLibrary, size: 28)
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
                        VStack(alignment: .leading, spacing: 8) {
                            Text(note.body)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            if let archivedAt = note.archivedAt {
                                Text(archivedAt, format: .dateTime.month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
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
