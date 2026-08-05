import SwiftUI

struct NoteLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var feature: IslandNotesFeature

    var body: some View {
        Group {
            if feature.library.isEmpty {
                ContentUnavailableView(
                    "便签库还是空的",
                    systemImage: "tray",
                    description: Text("把当前便签放入库后，会在这里按最近时间排列。")
                )
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
                    .accessibilityLabel("便签：\(note.body)")
                    .accessibilityHint("轻点与当前便签交换")
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("便签库")
        .navigationBarTitleDisplayMode(.large)
    }
}
