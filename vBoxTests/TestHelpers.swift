//
//  TestHelpers.swift
//  vBoxTests
//
//  Common test utilities and helpers
//

import XCTest
import CoreLocation
@testable import vBox

// MARK: - Test Data Builders

/// Helper for creating test BLE data packets
enum TestBLEDataBuilder {

    /// Create valid BLE data with correct checksum
    static func createValidPacket(
        time: UInt32 = 0,
        pid: UInt16,
        flags: UInt8 = 0,
        value: Float
    ) -> Data {
        var data = Data(count: 12)

        // Write time (4 bytes)
        withUnsafeBytes(of: time) { data.replaceSubrange(0..<4, with: $0) }

        // Write PID (2 bytes)
        withUnsafeBytes(of: pid) { data.replaceSubrange(4..<6, with: $0) }

        // Write flags (1 byte)
        data[6] = flags

        // Write value (4 bytes starting at offset 8)
        withUnsafeBytes(of: value) { data.replaceSubrange(8..<12, with: $0) }

        // Calculate checksum for first 11 bytes and store at index 7
        var checksum: UInt8 = 0
        for i in 0..<7 {
            checksum ^= data[i]
        }
        for i in 8..<12 {
            checksum ^= data[i]
        }
        data[7] = checksum

        return data
    }

    /// Create a speed reading packet
    static func speedPacket(value: Float) -> Data {
        return createValidPacket(pid: OBDPID.speed.rawValue, value: value)
    }

    /// Create an RPM reading packet
    static func rpmPacket(value: Float) -> Data {
        return createValidPacket(pid: OBDPID.rpm.rawValue, value: value)
    }

    /// Create a fuel level reading packet
    static func fuelPacket(value: Float) -> Data {
        return createValidPacket(pid: OBDPID.fuelLevel.rawValue, value: value)
    }
}

// MARK: - Test Location Helpers

/// Helper for creating test locations
enum TestLocationBuilder {

    /// San Francisco coordinates
    static let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    /// Los Angeles coordinates
    static let losAngeles = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)

    /// New York coordinates
    static let newYork = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)

    /// Create a CLLocation with the given parameters
    static func location(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        speed: Double = 0,
        timestamp: Date = Date()
    ) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 0,
            speed: speed,
            timestamp: timestamp
        )
    }

    /// Create a path of locations simulating a trip
    static func tripPath(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        pointCount: Int = 10,
        duration: TimeInterval = 3600
    ) -> [CLLocation] {
        var locations: [CLLocation] = []
        let startTime = Date(timeIntervalSinceNow: -duration)

        for i in 0..<pointCount {
            let progress = Double(i) / Double(pointCount - 1)

            let lat = start.latitude + (end.latitude - start.latitude) * progress
            let lon = start.longitude + (end.longitude - start.longitude) * progress
            let timestamp = startTime.addingTimeInterval(duration * progress)

            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                course: 0,
                speed: 20, // 20 m/s ~ 72 km/h
                timestamp: timestamp
            )

            locations.append(location)
        }

        return locations
    }
}

// MARK: - Test Diagnostics Helpers

/// Helper for creating test vehicle diagnostics
enum TestDiagnosticsBuilder {

    /// Create a VehicleDiagnostics with typical idle values
    static func idleDiagnostics() -> VehicleDiagnostics {
        var diagnostics = VehicleDiagnostics()
        diagnostics.update(with: DiagnosticReading(pid: .speed, value: 0))
        diagnostics.update(with: DiagnosticReading(pid: .rpm, value: 800))
        diagnostics.update(with: DiagnosticReading(pid: .fuelLevel, value: 75))
        diagnostics.update(with: DiagnosticReading(pid: .coolantTemp, value: 85))
        diagnostics.update(with: DiagnosticReading(pid: .engineLoad, value: 15))
        return diagnostics
    }

    /// Create a VehicleDiagnostics with typical highway driving values
    static func highwayDiagnostics() -> VehicleDiagnostics {
        var diagnostics = VehicleDiagnostics()
        diagnostics.update(with: DiagnosticReading(pid: .speed, value: 120))
        diagnostics.update(with: DiagnosticReading(pid: .rpm, value: 3500))
        diagnostics.update(with: DiagnosticReading(pid: .fuelLevel, value: 60))
        diagnostics.update(with: DiagnosticReading(pid: .coolantTemp, value: 90))
        diagnostics.update(with: DiagnosticReading(pid: .engineLoad, value: 45))
        diagnostics.update(with: DiagnosticReading(pid: .throttle, value: 30))
        return diagnostics
    }

    /// Create a sequence of diagnostic readings simulating acceleration
    static func accelerationSequence(
        fromSpeed startSpeed: Float = 0,
        toSpeed endSpeed: Float = 100,
        duration: TimeInterval = 10,
        readings: Int = 10
    ) -> [DiagnosticReading] {
        var result: [DiagnosticReading] = []
        let startTime = Date()

        for i in 0..<readings {
            let progress = Float(i) / Float(readings - 1)
            let speed = startSpeed + (endSpeed - startSpeed) * progress
            let timestamp = startTime.addingTimeInterval(duration * Double(progress))

            result.append(DiagnosticReading(pid: .speed, value: speed, timestamp: timestamp))

            // Also add corresponding RPM readings
            let rpm = 1000 + (speed * 40) // Simple relationship
            result.append(DiagnosticReading(pid: .rpm, value: rpm, timestamp: timestamp))
        }

        return result
    }
}

// MARK: - XCTest Async Helpers

extension XCTestCase {

    /// Wait for a condition with timeout
    func wait(
        for condition: @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        pollInterval: TimeInterval = 0.1,
        description: String = "Condition"
    ) {
        let expectation = XCTestExpectation(description: description)

        let startTime = Date()
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("\(description) timed out after \(timeout) seconds")
                return
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: pollInterval))
        }

        expectation.fulfill()
    }
}

// MARK: - Test Date Helpers

extension Date {
    /// Create a date for testing with specific components
    static func testDate(
        year: Int = 2024,
        month: Int = 1,
        day: Int = 1,
        hour: Int = 12,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Comparison Helpers

/// Floating point comparison with tolerance
func assertAlmostEqual(
    _ actual: Float,
    _ expected: Float,
    tolerance: Float = 0.001,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(actual, expected, accuracy: tolerance, file: file, line: line)
}

func assertAlmostEqual(
    _ actual: Double,
    _ expected: Double,
    tolerance: Double = 0.001,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(actual, expected, accuracy: tolerance, file: file, line: line)
}
