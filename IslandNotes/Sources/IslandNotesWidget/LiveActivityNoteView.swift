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
    var foregroundColor: Color = .primary

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
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(surface == .lockScreen ? LiveActivityDesign.lockScreenPadding : 0)
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

struct LiveActivityLockScreenView: View {
    let presentation: LiveActivityPresentation

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        LiveActivityNoteView(
            presentation: presentation,
            surface: .lockScreen,
            foregroundColor: foregroundColor
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: LiveActivityDesign.lockScreenCornerRadius,
                style: .continuous
            )
            .stroke(
                LiveActivityDesign.lockScreenBorderColor(
                    usesDarkAppearance: usesDarkAppearance
                ),
                lineWidth: LiveActivityDesign.lockScreenBorderWidth
            )
        }
        .activityBackgroundTint(backgroundColor)
        .activitySystemActionForegroundColor(foregroundColor)
    }

    private var usesDarkAppearance: Bool {
        colorScheme == .dark || isLuminanceReduced
    }

    private var foregroundColor: Color {
        LiveActivityDesign.lockScreenForegroundColor(
            usesDarkAppearance: usesDarkAppearance
        )
    }

    private var backgroundColor: Color {
        LiveActivityDesign.lockScreenBackgroundColor(
            usesDarkAppearance: usesDarkAppearance
        )
    }
}
