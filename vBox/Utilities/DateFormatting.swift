//
//  DateFormatting.swift
//  vBox
//
//  Swift utilities for date and time formatting
//

import Foundation

// MARK: - Duration Formatting

/// Formats a time duration into a human-readable string
enum DurationFormatter {

    /// Format a time interval as HH:MM:SS
    /// - Parameter interval: Time interval in seconds
    /// - Returns: Formatted string like "01:23:45"
    static func string(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds / 60) % 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Format the duration between two dates as HH:MM:SS
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Formatted string like "01:23:45"
    static func string(from startDate: Date, to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(startDate)
        return string(from: interval)
    }

    /// Format a time interval in a human-readable way
    /// - Parameter interval: Time interval in seconds
    /// - Returns: Human-readable string like "2 hours 15 minutes"
    static func humanReadable(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)

        if totalSeconds < 60 {
            return "\(totalSeconds) second\(totalSeconds == 1 ? "" : "s")"
        }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds / 60) % 60

        if hours == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }

        if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }

        return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) minute\(minutes == 1 ? "" : "s")"
    }
}

// MARK: - Date Formatting

/// Formats dates for display in the app
enum DateDisplayFormatter {

    // MARK: - Shared Formatters (reused for performance)

    private static let fullDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy (EEEE) HH:mm:ss"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let mediumDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()

    // MARK: - Public Methods

    /// Format date as "March 15, 2024 (Friday) 14:30:00"
    static func fullDateTime(_ date: Date) -> String {
        return fullDateTimeFormatter.string(from: date)
    }

    /// Format date as short date (locale-specific)
    static func shortDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }

    /// Format time as short time (locale-specific)
    static func shortTime(_ date: Date) -> String {
        return shortTimeFormatter.string(from: date)
    }

    /// Format as medium date with short time
    static func mediumDateTime(_ date: Date) -> String {
        return mediumDateTimeFormatter.string(from: date)
    }

    /// Format as day of week (e.g., "Friday")
    static func dayOfWeek(_ date: Date) -> String {
        return dayOfWeekFormatter.string(from: date)
    }

    /// Format as month and day (e.g., "March 15")
    static func monthDay(_ date: Date) -> String {
        return monthDayFormatter.string(from: date)
    }

    /// Relative date description (Today, Yesterday, or formatted date)
    static func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return dayOfWeek(date)
        } else {
            return shortDate(date)
        }
    }

    /// Trip timestamp format: relative date + time
    static func tripTimestamp(_ date: Date) -> String {
        return "\(relativeDate(date)) at \(shortTime(date))"
    }
}

// MARK: - Date Extensions

extension Date {
    /// Duration since this date in HH:MM:SS format
    var durationSinceNow: String {
        return DurationFormatter.string(from: self, to: Date())
    }

    /// Full date time string
    var fullDateTimeString: String {
        return DateDisplayFormatter.fullDateTime(self)
    }

    /// Relative date string
    var relativeDateString: String {
        return DateDisplayFormatter.relativeDate(self)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Duration in HH:MM:SS format
    var durationString: String {
        return DurationFormatter.string(from: self)
    }

    /// Human readable duration
    var humanReadableDuration: String {
        return DurationFormatter.humanReadable(from: self)
    }
}
