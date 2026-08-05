import SwiftUI
import UIKit

struct MarkedTextEditor: UIViewRepresentable {
    let text: String
    let onChange: (String, Bool) -> Void

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
        textView.accessibilityLabel = "当前便签"
        textView.accessibilityHint = "直接编辑，内容会自动保存"
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
            parent.onChange(textView.text, textView.markedTextRange != nil)
        }
    }
}
