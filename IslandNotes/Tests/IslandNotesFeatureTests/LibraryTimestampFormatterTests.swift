import XCTest
@testable import IslandNotes

final class LibraryTimestampFormatterTests: XCTestCase {
    private let timeZone = TimeZone(secondsFromGMT: 0)!

    func testTodayUsesRelativeLabelAndTwelveHourTime() throws {
        let now = try date(2026, 8, 5, 12, 0)
        let formatter = makeFormatter(now: now)

        XCTAssertEqual(
            formatter.string(from: try date(2026, 8, 5, 9, 41)),
            "Today, 9:41 AM"
        )
    }

    func testYesterdayUsesRelativeLabel() throws {
        let formatter = makeFormatter(now: try date(2026, 8, 5, 12, 0))

        XCTAssertEqual(
            formatter.string(from: try date(2026, 8, 4, 21, 18)),
            "Yesterday, 9:18 PM"
        )
    }

    func testRecentDateUsesEnglishWeekday() throws {
        let formatter = makeFormatter(now: try date(2026, 8, 5, 12, 0))

        XCTAssertEqual(
            formatter.string(from: try date(2026, 8, 3, 7, 30)),
            "Monday, 7:30 AM"
        )
    }

    func testOlderDateInSameYearOmitsYear() throws {
        let formatter = makeFormatter(now: try date(2026, 8, 5, 12, 0))

        XCTAssertEqual(
            formatter.string(from: try date(2026, 6, 14, 14, 5)),
            "Jun 14, 2:05 PM"
        )
    }

    func testDateInPriorYearIncludesYear() throws {
        let formatter = makeFormatter(now: try date(2026, 8, 5, 12, 0))

        XCTAssertEqual(
            formatter.string(from: try date(2025, 12, 31, 23, 59)),
            "Dec 31, 2025, 11:59 PM"
        )
    }

    func testOutputIsEnglishAndTwelveHourRegardlessOfDevicePreferences() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ar_SA")
        calendar.timeZone = timeZone
        let formatter = LibraryTimestampFormatter(
            calendar: calendar,
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: timeZone,
            now: { try! self.date(2026, 8, 5, 12, 0) }
        )

        XCTAssertEqual(
            formatter.string(from: try date(2026, 8, 5, 21, 7)),
            "Today, 9:07 PM"
        )
    }

    private func makeFormatter(now: Date) -> LibraryTimestampFormatter {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        return LibraryTimestampFormatter(
            calendar: calendar,
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: timeZone,
            now: { now }
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    timeZone: timeZone,
                    year: year,
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                )
            )
        )
    }
}
