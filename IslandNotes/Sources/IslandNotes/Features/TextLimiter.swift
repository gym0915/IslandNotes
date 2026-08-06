import Foundation

struct TextLimitResult: Equatable, Sendable {
    let acceptedText: String
    let wasTruncated: Bool
    let isAtLimit: Bool
}

struct TextChangeLimitResult: Equatable, Sendable {
    let acceptedText: String
    let wasTruncated: Bool
    let isAtLimit: Bool
    let selectionUTF16Offset: Int
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

    static func limitChange(
        currentText: String,
        proposedText: String
    ) -> TextChangeLimitResult {
        let current = Array(currentText)
        let proposed = Array(proposedText)
        var commonPrefixCount = 0

        while commonPrefixCount < min(current.count, proposed.count),
              current[commonPrefixCount] == proposed[commonPrefixCount] {
            commonPrefixCount += 1
        }

        var commonSuffixCount = 0
        while commonSuffixCount < current.count - commonPrefixCount,
              commonSuffixCount < proposed.count - commonPrefixCount,
              current[current.count - commonSuffixCount - 1]
                == proposed[proposed.count - commonSuffixCount - 1] {
            commonSuffixCount += 1
        }

        let prefix = current.prefix(commonPrefixCount)
        let suffix = current.suffix(commonSuffixCount)
        let replacementEnd = proposed.count - commonSuffixCount
        let proposedReplacement = proposed[commonPrefixCount..<replacementEnd]
        let availableCount = max(
            0,
            maximumCharacterCount - prefix.count - suffix.count
        )
        let acceptedReplacement = proposedReplacement.prefix(availableCount)
        let acceptedCharacters = prefix + acceptedReplacement + suffix
        let acceptedText = String(acceptedCharacters)
        let selectionOffset = String(prefix + acceptedReplacement).utf16.count

        return TextChangeLimitResult(
            acceptedText: acceptedText,
            wasTruncated: acceptedText != proposedText,
            isAtLimit: acceptedCharacters.count == maximumCharacterCount,
            selectionUTF16Offset: selectionOffset
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
