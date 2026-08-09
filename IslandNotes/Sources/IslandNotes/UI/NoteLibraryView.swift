import SwiftUI

struct NoteLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var feature: IslandNotesFeature
    private let timestampFormatter: LibraryTimestampFormatter

    init(
        feature: IslandNotesFeature,
        timestampFormatter: LibraryTimestampFormatter = LibraryTimestampFormatter()
    ) {
        self.feature = feature
        self.timestampFormatter = timestampFormatter
    }

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
                ScrollView {
                    VStack(alignment: .leading, spacing: IslandDesign.Spacing.x2) {
                        Text("Recent")
                            .font(IslandDesign.Typography.caption)
                            .foregroundStyle(IslandDesign.Colors.secondaryText)
                            .textCase(.uppercase)
                            .padding(.horizontal, IslandDesign.Spacing.x1)

                        IslandSurface {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(feature.library.enumerated()), id: \.element.id) { index, note in
                                    LibraryNoteCard(
                                        note: note,
                                        timestamp: timestampFormatter.string(
                                            from: note.archivedAt ?? note.modifiedAt
                                        ),
                                        replacementEnabled: feature.canSelectLibraryNote,
                                        replacementHint: replacementHint
                                    ) {
                                        replaceCurrentNote(with: note.id)
                                    }

                                    if index < feature.library.count - 1 {
                                        Divider()
                                            .overlay(IslandDesign.Colors.separator)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, IslandDesign.Spacing.x4)
                    .padding(.top, IslandDesign.Spacing.x2)
                    .padding(.bottom, IslandDesign.Spacing.x8)
                }
            }
        }
    }

    private var replacementHint: String {
        feature.canSelectLibraryNote
            ? "Replaces the current note"
            : feature.noteMutationAvailability.accessibilityHint
    }

    private func replaceCurrentNote(with id: UUID) {
        Task {
            try? await feature.selectLibraryNote(id: id)
            if feature.currentNote?.id == id { dismiss() }
        }
    }
}
