import SwiftUI

enum LiveActivityNoteSurface {
    case expandedIsland
    case lockScreen
}

struct LiveActivityBrandMarkView: View {
    let size: CGFloat

    var body: some View {
        Image("lucide-notebook-text")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct LiveActivityNoteView: View {
    let presentation: LiveActivityPresentation
    let surface: LiveActivityNoteSurface

    var body: some View {
        HStack(alignment: .top, spacing: LiveActivityDesign.contentSpacing) {
            if presentation.brandMark == .notebookText {
                LiveActivityBrandMarkView(size: LiveActivityDesign.brandMarkSize)
                    .padding(.top, 1)
            }

            Text(presentation.body ?? "")
                .font(contentFont)
                .lineLimit(presentation.lineLimit)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.primary)
        .padding(surface == .lockScreen ? LiveActivityDesign.lockScreenPadding : 0)
        .background {
            if surface == .lockScreen {
                RoundedRectangle(
                    cornerRadius: LiveActivityDesign.lockScreenCornerRadius,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: LiveActivityDesign.lockScreenCornerRadius,
                        style: .continuous
                    )
                    .stroke(.primary.opacity(0.14), lineWidth: 1)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityLabel ?? "Island Notes")
    }

    private var contentFont: Font {
        switch surface {
        case .expandedIsland:
            LiveActivityDesign.expandedFont
        case .lockScreen:
            LiveActivityDesign.lockScreenFont
        }
    }
}
