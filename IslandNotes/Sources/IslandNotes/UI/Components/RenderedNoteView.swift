import SwiftUI

struct RenderedNoteView: View {
    let source: String

    var body: some View {
        if source.isEmpty {
            Text("Add something you want to keep close, then go live on Dynamic Island.")
                .font(IslandDesign.Typography.noteBody)
                .foregroundStyle(IslandDesign.Colors.secondaryText)
        } else {
            VStack(alignment: .leading, spacing: IslandDesign.Spacing.x2) {
                ForEach(Array(RenderedNoteContent.lines(from: source).enumerated()), id: \.offset) {
                    item in
                    renderedLine(item.element)
                }
            }
            .font(IslandDesign.Typography.noteBody)
            .foregroundStyle(IslandDesign.Colors.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func renderedLine(_ line: RenderedNoteLine) -> some View {
        switch line {
        case let .text(text):
            Text(text.isEmpty ? " " : text)
                .accessibilityLabel(text.isEmpty ? "Blank line" : text)
        case let .bullet(text):
            HStack(alignment: .firstTextBaseline, spacing: IslandDesign.Spacing.x2) {
                Circle()
                    .fill(IslandDesign.Colors.primaryText)
                    .frame(
                        width: IslandDesign.Sizing.listBullet,
                        height: IslandDesign.Sizing.listBullet
                    )
                    .accessibilityHidden(true)
                Text(text.isEmpty ? " " : text)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(text.isEmpty ? "Empty bullet" : "Bullet, \(text)")
        }
    }
}
