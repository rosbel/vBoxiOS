//
//  DateFormattingTests.swift
//  vBoxTests
//
//  Tests for date and time formatting utilities
//

import XCTest
@testable import vBox

// MARK: - Duration Formatter Tests

final class DurationFormatterTests: XCTestCase {

    // MARK: - Basic Duration Formatting

    func testZeroDuration() {
        XCTAssertEqual(DurationFormatter.string(from: 0), "00:00:00")
    }

    func testSecondsOnly() {
        XCTAssertEqual(DurationFormatter.string(from: 45), "00:00:45")
    }

    func testMinutesAndSeconds() {
        XCTAssertEqual(DurationFormatter.string(from: 125), "00:02:05")
    }

    func testHoursMinutesSeconds() {
        XCTAssertEqual(DurationFormatter.string(from: 3723), "01:02:03")
    }

    func testExactlyOneHour() {
        XCTAssertEqual(DurationFormatter.string(from: 3600), "01:00:00")
    }

    func testMultipleHours() {
        XCTAssertEqual(DurationFormatter.string(from: 36000), "10:00:00")
    }

    func testLargeDuration() {
        // 99 hours, 59 minutes, 59 seconds
        XCTAssertEqual(DurationFormatter.string(from: 359999), "99:59:59")
    }

    // MARK: - Duration Between Dates

    func testDurationBetweenDates() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 3723)

        XCTAssertEqual(DurationFormatter.string(from: start, to: end), "01:02:03")
    }

    func testDurationBetweenSameDates() {
        let date = Date()
        XCTAssertEqual(DurationFormatter.string(from: date, to: date), "00:00:00")
    }

    // MARK: - Human Readable Duration

    func testHumanReadableSeconds() {
        XCTAssertEqual(DurationFormatter.humanReadable(from: 1), "1 second")
        XCTAssertEqual(DurationFormatter.humanReadable(from: 30), "30 seconds")
    }

    func testHumanReadableMinutes() {
        XCTAssertEqual(DurationFormatter.humanReadable(from: 60), "1 minute")
        XCTAssertEqual(DurationFormatter.humanReadable(from: 120), "2 minutes")
        XCTAssertEqual(DurationFormatter.humanReadable(from: 300), "5 minutes")
    }

    func testHumanReadableHours() {
        XCTAssertEqual(DurationFormatter.humanReadable(from: 3600), "1 hour")
        XCTAssertEqual(DurationFormatter.humanReadable(from: 7200), "2 hours")
    }

    func testHumanReadableHoursAndMinutes() {
        XCTAssertEqual(DurationFormatter.humanReadable(from: 3660), "1 hour 1 minute")
        XCTAssertEqual(DurationFormatter.humanReadable(from: 7500), "2 hours 5 minutes")
    }
}

// MARK: - Date Display Formatter Tests

final class DateDisplayFormatterTests: XCTestCase {

    // MARK: - Full Date Time

    func testFullDateTimeFormatIncludesExpectedComponents() {
        let date = createDate(year: 2024, month: 3, day: 15, hour: 14, minute: 30, second: 45)
        let result = DateDisplayFormatter.fullDateTime(date)

        // The format is "MMMM dd, yyyy (EEEE) HH:mm:ss"
        XCTAssertTrue(result.contains("March"))
        XCTAssertTrue(result.contains("15"))
        XCTAssertTrue(result.contains("2024"))
        XCTAssertTrue(result.contains("14:30:45"))
    }

    // MARK: - Short Date

    func testShortDateReturnsNonEmptyString() {
        let date = Date()
        let result = DateDisplayFormatter.shortDate(date)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Short Time

    func testShortTimeReturnsNonEmptyString() {
        let date = Date()
        let result = DateDisplayFormatter.shortTime(date)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Medium Date Time

    func testMediumDateTimeReturnsNonEmptyString() {
        let date = Date()
        let result = DateDisplayFormatter.mediumDateTime(date)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Day of Week

    func testDayOfWeekFriday() {
        // March 15, 2024 is a Friday
        let date = createDate(year: 2024, month: 3, day: 15)
        let result = DateDisplayFormatter.dayOfWeek(date)
        XCTAssertEqual(result, "Friday")
    }

    func testDayOfWeekSunday() {
        // March 17, 2024 is a Sunday
        let date = createDate(year: 2024, month: 3, day: 17)
        let result = DateDisplayFormatter.dayOfWeek(date)
        XCTAssertEqual(result, "Sunday")
    }

    // MARK: - Month Day

    func testMonthDay() {
        let date = createDate(year: 2024, month: 3, day: 15)
        let result = DateDisplayFormatter.monthDay(date)
        XCTAssertEqual(result, "March 15")
    }

    func testMonthDayJanuary() {
        let date = createDate(year: 2024, month: 1, day: 1)
        let result = DateDisplayFormatter.monthDay(date)
        XCTAssertEqual(result, "January 1")
    }

    // MARK: - Relative Date

    func testRelativeDateToday() {
        let today = Date()
        let result = DateDisplayFormatter.relativeDate(today)
        XCTAssertEqual(result, "Today")
    }

    func testRelativeDateYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = DateDisplayFormatter.relativeDate(yesterday)
        XCTAssertEqual(result, "Yesterday")
    }

    func testRelativeDateOlderDate() {
        // A date from last month should return short date
        let oldDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let result = DateDisplayFormatter.relativeDate(oldDate)
        // Should be short date format, not "Today" or "Yesterday"
        XCTAssertNotEqual(result, "Today")
        XCTAssertNotEqual(result, "Yesterday")
    }

    // MARK: - Trip Timestamp

    func testTripTimestampToday() {
        let today = Date()
        let result = DateDisplayFormatter.tripTimestamp(today)
        XCTAssertTrue(result.hasPrefix("Today at "))
    }

    func testTripTimestampYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = DateDisplayFormatter.tripTimestamp(yesterday)
        XCTAssertTrue(result.hasPrefix("Yesterday at "))
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Date Extension Tests

final class DateExtensionTests: XCTestCase {

    func testFullDateTimeString() {
        let date = Date()
        let result = date.fullDateTimeString
        XCTAssertFalse(result.isEmpty)
    }

    func testRelativeDateString() {
        let date = Date()
        XCTAssertEqual(date.relativeDateString, "Today")
    }
}

// MARK: - TimeInterval Extension Tests

final class TimeIntervalExtensionTests: XCTestCase {

    func testDurationString() {
        let interval: TimeInterval = 3723
        XCTAssertEqual(interval.durationString, "01:02:03")
    }

    func testHumanReadableDuration() {
        let interval: TimeInterval = 7500
        XCTAssertEqual(interval.humanReadableDuration, "2 hours 5 minutes")
    }
}

// MARK: - Backward Compatibility Tests

final class UtilityMethodsCompatibilityTests: XCTestCase {

    /// Test that Swift formatting matches the Objective-C UtilityMethods output
    func testDurationStringMatchesObjCFormat() {
        // The Obj-C method returns "HH:MM:SS" format
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 3723) // 1 hour, 2 min, 3 sec

        let swiftResult = DurationFormatter.string(from: start, to: end)

        // Should match Obj-C format exactly
        XCTAssertEqual(swiftResult, "01:02:03")
    }

    func testFullDateTimeMatchesObjCFormat() {
        // The Obj-C format is "MMMM dd, yyy (EEEE) HH:mm:ss"
        // Note: There's a typo in the Obj-C ("yyy" instead of "yyyy") but it still works
        let date = createDate(year: 2024, month: 3, day: 15, hour: 14, minute: 30, second: 45)
        let result = DateDisplayFormatter.fullDateTime(date)

        // Verify it contains all expected components
        XCTAssertTrue(result.contains("March"))
        XCTAssertTrue(result.contains("15"))
        XCTAssertTrue(result.contains("2024"))
        XCTAssertTrue(result.contains("Friday"))
        XCTAssertTrue(result.contains("14:30:45"))
    }

    private func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }
}
