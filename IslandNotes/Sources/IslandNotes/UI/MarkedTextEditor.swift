import SwiftUI
import UIKit

struct MarkedTextEditor: UIViewRepresentable {
    let text: String
    let onChange: (String, Bool) -> String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .title2)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
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
        guard textView.markedTextRange == nil, textView.text != text else { return }
        textView.text = text
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkedTextEditor

        init(parent: MarkedTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            let markedTextActive = textView.markedTextRange != nil
            let acceptedText = parent.onChange(textView.text, markedTextActive)
            guard !markedTextActive, acceptedText != textView.text else { return }

            let insertionOffset = min(
                textView.selectedRange.location,
                acceptedText.utf16.count
            )
            textView.text = acceptedText
            textView.selectedRange = NSRange(location: insertionOffset, length: 0)
        }
    }
}
