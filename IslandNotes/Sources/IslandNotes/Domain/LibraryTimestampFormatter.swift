import Foundation

struct LibraryTimestampFormatter {
    private var calendar: Calendar
    private let locale: Locale
    private let timeZone: TimeZone
    private let now: () -> Date

    init(
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone = .current,
        now: @escaping () -> Date = Date.init
    ) {
        var configuredCalendar = calendar
        configuredCalendar.locale = locale
        configuredCalendar.timeZone = timeZone
        self.calendar = configuredCalendar
        self.locale = locale
        self.timeZone = timeZone
        self.now = now
    }

    func string(from date: Date) -> String {
        let reference = now()
        let dateStart = calendar.startOfDay(for: date)
        let referenceStart = calendar.startOfDay(for: reference)
        let dayDistance = calendar.dateComponents(
            [.day],
            from: dateStart,
            to: referenceStart
        ).day ?? .max

        let dateLabel: String
        switch dayDistance {
        case 0:
            dateLabel = "Today"
        case 1:
            dateLabel = "Yesterday"
        case 2...6:
            dateLabel = formatted(date, pattern: "EEEE")
        default:
            let includesYear = calendar.component(.year, from: date)
                != calendar.component(.year, from: reference)
            dateLabel = formatted(date, pattern: includesYear ? "MMM d, yyyy" : "MMM d")
        }

        return "\(dateLabel), \(formatted(date, pattern: "h:mm a"))"
    }

    private func formatted(_ date: Date, pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
