import Foundation

struct TextLimitResult: Equatable, Sendable {
    let acceptedText: String
    let wasTruncated: Bool
    let isAtLimit: Bool
}

enum TextLimiter {
    static let maximumCharacterCount = 240

    static func limit(
        proposedText: String,
        markedTextActive: Bool
    ) -> TextLimitResult {
        if markedTextActive {
            return TextLimitResult(
                acceptedText: proposedText,
                wasTruncated: false,
                isAtLimit: false
            )
        }

        let acceptedText = String(proposedText.prefix(maximumCharacterCount))
        return TextLimitResult(
            acceptedText: acceptedText,
            wasTruncated: acceptedText != proposedText,
            isAtLimit: acceptedText.count == maximumCharacterCount
        )
    }
}

struct CharacterProgress: Equatable, Sendable {
    let used: Int
    let remaining: Int

    var accessibilityValue: String {
        "\(used) used, \(remaining) remaining"
    }
}
