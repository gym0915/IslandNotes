import Foundation

struct LibraryTimestampFormatter {
    private var calendar: Calendar
    private let now: () -> Date
    private let formatters: LibraryTimestampFormatters

    init(
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone = .current,
        now: @escaping () -> Date = Date.init,
        formatterFactory: () -> DateFormatter = DateFormatter.init
    ) {
        var configuredCalendar = calendar
        configuredCalendar.locale = locale
        configuredCalendar.timeZone = timeZone
        self.calendar = configuredCalendar
        self.now = now
        formatters = LibraryTimestampFormatters(
            calendar: configuredCalendar,
            locale: locale,
            timeZone: timeZone,
            factory: formatterFactory
        )
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
            dateLabel = formatters.weekday.string(from: date)
        default:
            let includesYear = calendar.component(.year, from: date)
                != calendar.component(.year, from: reference)
            dateLabel = (includesYear ? formatters.dateWithYear : formatters.date)
                .string(from: date)
        }

        return "\(dateLabel), \(formatters.time.string(from: date))"
    }
}

private final class LibraryTimestampFormatters {
    let weekday: DateFormatter
    let date: DateFormatter
    let dateWithYear: DateFormatter
    let time: DateFormatter

    init(
        calendar: Calendar,
        locale: Locale,
        timeZone: TimeZone,
        factory: () -> DateFormatter
    ) {
        weekday = Self.make(
            pattern: "EEEE",
            calendar: calendar,
            locale: locale,
            timeZone: timeZone,
            factory: factory
        )
        date = Self.make(
            pattern: "MMM d",
            calendar: calendar,
            locale: locale,
            timeZone: timeZone,
            factory: factory
        )
        dateWithYear = Self.make(
            pattern: "MMM d, yyyy",
            calendar: calendar,
            locale: locale,
            timeZone: timeZone,
            factory: factory
        )
        time = Self.make(
            pattern: "h:mm a",
            calendar: calendar,
            locale: locale,
            timeZone: timeZone,
            factory: factory
        )
    }

    private static func make(
        pattern: String,
        calendar: Calendar,
        locale: Locale,
        timeZone: TimeZone,
        factory: () -> DateFormatter
    ) -> DateFormatter {
        let formatter = factory()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter
    }
}
