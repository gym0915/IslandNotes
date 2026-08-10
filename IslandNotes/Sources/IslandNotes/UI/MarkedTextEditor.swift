import SwiftUI
import UIKit

struct MarkedTextEditor: UIViewRepresentable {
    let text: String
    let textContainerInset: UIEdgeInsets
    let onChange: (String, Bool) -> String
    let onMarkedTextChange: (Bool) -> Void

    init(
        text: String,
        textContainerInset: UIEdgeInsets = UIEdgeInsets(
            top: IslandDesign.Spacing.x1,
            left: 0,
            bottom: IslandDesign.Spacing.x1,
            right: 0
        ),
        onChange: @escaping (String, Bool) -> String,
        onMarkedTextChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.text = text
        self.textContainerInset = textContainerInset
        self.onChange = onChange
        self.onMarkedTextChange = onMarkedTextChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .preferredFont(
            forTextStyle: IslandDesign.Typography.editorTextStyle
        )
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = textContainerInset
        textView.textContainer.lineFragmentPadding = 0
        textView.keyboardDismissMode = .interactive
        textView.accessibilityIdentifier = "current-note-editor"
        textView.accessibilityLabel = "Current note"
        textView.accessibilityHint = "Edit the current note"
        Task { @MainActor [weak textView] in
            textView?.becomeFirstResponder()
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        textView.textContainerInset = textContainerInset
        if textView.markedTextRange == nil {
            context.coordinator.committedText = text
        }
        guard textView.markedTextRange == nil, textView.text != text else { return }
        textView.text = text
        textView.scrollRangeToVisible(textView.selectedRange)
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkedTextEditor
        var committedText: String
        private var compositionBaseline: String?

        init(parent: MarkedTextEditor) {
            self.parent = parent
            committedText = parent.text
        }

        func textViewDidChange(_ textView: UITextView) {
            let markedTextActive = textView.markedTextRange != nil
            parent.onMarkedTextChange(markedTextActive)
            if markedTextActive {
                if compositionBaseline == nil {
                    compositionBaseline = committedText
                }
                _ = parent.onChange(textView.text, true)
                return
            }

            let baseline = compositionBaseline ?? committedText
            compositionBaseline = nil
            let limitResult = TextLimiter.limitChange(
                currentText: baseline,
                proposedText: textView.text
            )
            let acceptedText = parent.onChange(limitResult.acceptedText, false)
            committedText = acceptedText
            guard acceptedText != textView.text else {
                textView.scrollRangeToVisible(textView.selectedRange)
                return
            }

            textView.text = acceptedText
            textView.selectedRange = NSRange(
                location: min(limitResult.selectionUTF16Offset, acceptedText.utf16.count),
                length: 0
            )
            textView.scrollRangeToVisible(textView.selectedRange)
        }
    }
}
