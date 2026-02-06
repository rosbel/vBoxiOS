//
//  OBDTypesTests.swift
//  vBoxTests
//
//  Tests for OBD-II protocol types
//

import XCTest
@testable import vBox

final class OBDPIDTests: XCTestCase {

    // MARK: - PID Raw Values

    func testSpeedPIDRawValue() {
        XCTAssertEqual(OBDPID.speed.rawValue, 0x10D)
    }

    func testRPMPIDRawValue() {
        XCTAssertEqual(OBDPID.rpm.rawValue, 0x10C)
    }

    func testFuelLevelPIDRawValue() {
        XCTAssertEqual(OBDPID.fuelLevel.rawValue, 0x12F)
    }

    func testCoolantTempPIDRawValue() {
        XCTAssertEqual(OBDPID.coolantTemp.rawValue, 0x105)
    }

    func testEngineLoadPIDRawValue() {
        XCTAssertEqual(OBDPID.engineLoad.rawValue, 0x104)
    }

    func testThrottlePIDRawValue() {
        XCTAssertEqual(OBDPID.throttle.rawValue, 0x111)
    }

    // MARK: - PID Display Names

    func testPIDDisplayNames() {
        XCTAssertEqual(OBDPID.speed.displayName, "Speed")
        XCTAssertEqual(OBDPID.rpm.displayName, "RPM")
        XCTAssertEqual(OBDPID.fuelLevel.displayName, "Fuel")
        XCTAssertEqual(OBDPID.coolantTemp.displayName, "Coolant Temp")
        XCTAssertEqual(OBDPID.engineLoad.displayName, "Engine Load")
        XCTAssertEqual(OBDPID.throttle.displayName, "Throttle")
        XCTAssertEqual(OBDPID.intakeTemp.displayName, "Intake Temp")
        XCTAssertEqual(OBDPID.ambientTemp.displayName, "Ambient Temp")
        XCTAssertEqual(OBDPID.barometric.displayName, "Barometric")
        XCTAssertEqual(OBDPID.distance.displayName, "Distance")
    }

    // MARK: - Max Valid Values

    func testMaxValidValues() {
        XCTAssertEqual(OBDPID.speed.maxValidValue, 1000.0)
        XCTAssertEqual(OBDPID.rpm.maxValidValue, 100000.0)
        XCTAssertEqual(OBDPID.fuelLevel.maxValidValue, 150.0)
        XCTAssertEqual(OBDPID.engineLoad.maxValidValue, 150.0)
        XCTAssertEqual(OBDPID.coolantTemp.maxValidValue, 500.0)
    }
}

// MARK: - BLE Data Packet Tests

final class BLEDataPacketTests: XCTestCase {

    // MARK: - Checksum Tests

    func testCalculateChecksumAllZeros() {
        let data = Data([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let checksum = BLEDataPacket.calculateChecksum(data: data, length: 12)
        XCTAssertEqual(checksum, 0)
    }

    func testCalculateChecksumSingleByte() {
        let data = Data([0xFF, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let checksum = BLEDataPacket.calculateChecksum(data: data, length: 12)
        XCTAssertEqual(checksum, 0xFF)
    }

    func testCalculateChecksumXORPattern() {
        // XOR of 0xAA and 0x55 should be 0xFF
        let data = Data([0xAA, 0x55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let checksum = BLEDataPacket.calculateChecksum(data: data, length: 12)
        XCTAssertEqual(checksum, 0xFF)
    }

    func testCalculateChecksumSelfCanceling() {
        // XOR of same value twice should be 0
        let data = Data([0xAB, 0xAB, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let checksum = BLEDataPacket.calculateChecksum(data: data, length: 12)
        XCTAssertEqual(checksum, 0)
    }

    func testValidateChecksumValid() {
        // Create data where XOR of all bytes = 0 (valid checksum)
        var data = Data([0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // Calculate what the last byte should be to make checksum = 0
        let partialChecksum = BLEDataPacket.calculateChecksum(data: data, length: 11)
        data[11] = partialChecksum
        XCTAssertTrue(BLEDataPacket.validateChecksum(data: data, length: 12))
    }

    func testValidateChecksumInvalid() {
        // Data that doesn't XOR to 0
        let data = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C])
        XCTAssertFalse(BLEDataPacket.validateChecksum(data: data, length: 12))
    }

    // MARK: - Packet Parsing Tests

    func testPacketTooShortReturnsNil() {
        let data = Data([0x01, 0x02, 0x03, 0x04])  // Only 4 bytes
        let packet = BLEDataPacket(data: data)
        XCTAssertNil(packet)
    }

    func testPacketInvalidChecksumReturnsNil() {
        // 12 bytes but invalid checksum
        let data = Data([0x00, 0x00, 0x00, 0x00,  // time
                         0x0D, 0x01,              // pid (speed)
                         0x00,                     // flags
                         0xFF,                     // bad checksum
                         0x00, 0x00, 0x00, 0x00]) // value
        let packet = BLEDataPacket(data: data)
        XCTAssertNil(packet)
    }

    func testPacketConstantsAreCorrect() {
        XCTAssertEqual(BLEDataPacket.legacyPacketSize, 12)
    }

    // MARK: - Direct Initialization Tests

    func testDirectInitialization() {
        let packet = BLEDataPacket(
            time: 12345,
            pid: OBDPID.speed.rawValue,
            flags: 0,
            checksum: 0,
            values: (65.0, 0, 0)
        )

        XCTAssertEqual(packet.time, 12345)
        XCTAssertEqual(packet.pid, OBDPID.speed.rawValue)
        XCTAssertEqual(packet.obdPID, .speed)
        XCTAssertEqual(packet.primaryValue, 65.0)
    }

    func testOBDPIDMapping() {
        let speedPacket = BLEDataPacket(time: 0, pid: 0x10D, flags: 0, checksum: 0, values: (0, 0, 0))
        XCTAssertEqual(speedPacket.obdPID, .speed)

        let rpmPacket = BLEDataPacket(time: 0, pid: 0x10C, flags: 0, checksum: 0, values: (0, 0, 0))
        XCTAssertEqual(rpmPacket.obdPID, .rpm)

        let unknownPacket = BLEDataPacket(time: 0, pid: 0xFFFF, flags: 0, checksum: 0, values: (0, 0, 0))
        XCTAssertNil(unknownPacket.obdPID)
    }
}

// MARK: - Diagnostic Reading Tests

final class DiagnosticReadingTests: XCTestCase {

    // MARK: - Initialization

    func testInitialization() {
        let reading = DiagnosticReading(pid: .speed, value: 65.0)

        XCTAssertEqual(reading.pid, .speed)
        XCTAssertEqual(reading.value, 65.0)
        XCTAssertNotNil(reading.timestamp)
    }

    func testInitializationWithTimestamp() {
        let date = Date(timeIntervalSince1970: 1000)
        let reading = DiagnosticReading(pid: .rpm, value: 3000, timestamp: date)

        XCTAssertEqual(reading.pid, .rpm)
        XCTAssertEqual(reading.value, 3000)
        XCTAssertEqual(reading.timestamp, date)
    }

    // MARK: - Validation

    func testValidSpeedReading() {
        let reading = DiagnosticReading(pid: .speed, value: 100.0)
        XCTAssertTrue(reading.isValid)
    }

    func testInvalidNegativeValue() {
        let reading = DiagnosticReading(pid: .speed, value: -10.0)
        XCTAssertFalse(reading.isValid)
    }

    func testInvalidExceedsMax() {
        let reading = DiagnosticReading(pid: .speed, value: 2000.0)  // max is 1000
        XCTAssertFalse(reading.isValid)
    }

    func testValidAtMaxValue() {
        let reading = DiagnosticReading(pid: .speed, value: 1000.0)
        XCTAssertTrue(reading.isValid)
    }

    func testValidAtZero() {
        let reading = DiagnosticReading(pid: .fuelLevel, value: 0.0)
        XCTAssertTrue(reading.isValid)
    }

    // MARK: - Display String

    func testSpeedDisplayString() {
        let reading = DiagnosticReading(pid: .speed, value: 65.0)
        XCTAssertEqual(reading.displayString, "65 km/h")
    }

    func testRPMDisplayString() {
        let reading = DiagnosticReading(pid: .rpm, value: 3000.0)
        XCTAssertEqual(reading.displayString, "3000 RPM")
    }

    func testFuelLevelDisplayString() {
        let reading = DiagnosticReading(pid: .fuelLevel, value: 75.0)
        XCTAssertEqual(reading.displayString, "75%")
    }

    func testCoolantTempDisplayString() {
        let reading = DiagnosticReading(pid: .coolantTemp, value: 90.0)
        XCTAssertEqual(reading.displayString, "90\u{00B0}C")
    }

    func testIntakeTempDisplayString() {
        let reading = DiagnosticReading(pid: .intakeTemp, value: 35.0)
        XCTAssertEqual(reading.displayString, "35\u{00B0}C")
    }

    func testAmbientTempDisplayString() {
        let reading = DiagnosticReading(pid: .ambientTemp, value: 25.0)
        XCTAssertEqual(reading.displayString, "25\u{00B0}C")
    }

    func testEngineLoadDisplayString() {
        let reading = DiagnosticReading(pid: .engineLoad, value: 45.5)
        XCTAssertEqual(reading.displayString, "45.5%")
    }

    func testThrottleDisplayString() {
        let reading = DiagnosticReading(pid: .throttle, value: 30.3)
        XCTAssertEqual(reading.displayString, "30.3%")
    }

    func testBarometricDisplayString() {
        let reading = DiagnosticReading(pid: .barometric, value: 101.0)
        XCTAssertEqual(reading.displayString, "101 kPa")
    }

    func testDistanceDisplayString() {
        let reading = DiagnosticReading(pid: .distance, value: 150.5)
        XCTAssertEqual(reading.displayString, "150.5 km")
    }
}

// MARK: - Vehicle Diagnostics Tests

final class VehicleDiagnosticsTests: XCTestCase {

    // MARK: - Initialization

    func testEmptyInitialization() {
        let diagnostics = VehicleDiagnostics()

        XCTAssertNil(diagnostics.speed)
        XCTAssertNil(diagnostics.rpm)
        XCTAssertNil(diagnostics.fuelLevel)
        XCTAssertNil(diagnostics.coolantTemp)
        XCTAssertNil(diagnostics.engineLoad)
        XCTAssertNil(diagnostics.throttle)
        XCTAssertNil(diagnostics.intakeTemp)
        XCTAssertNil(diagnostics.ambientTemp)
        XCTAssertNil(diagnostics.barometric)
        XCTAssertNil(diagnostics.distance)
    }

    // MARK: - Update with Reading

    func testUpdateSpeed() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .speed, value: 65.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.speed, 65.0)
    }

    func testUpdateRPM() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .rpm, value: 3000.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.rpm, 3000.0)
    }

    func testUpdateFuelLevel() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .fuelLevel, value: 75.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.fuelLevel, 75.0)
    }

    func testUpdateCoolantTemp() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .coolantTemp, value: 90.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.coolantTemp, 90.0)
    }

    func testUpdateEngineLoad() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .engineLoad, value: 45.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.engineLoad, 45.0)
    }

    func testUpdateThrottle() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .throttle, value: 30.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.throttle, 30.0)
    }

    func testUpdateIntakeTemp() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .intakeTemp, value: 35.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.intakeTemp, 35.0)
    }

    func testUpdateAmbientTemp() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .ambientTemp, value: 25.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.ambientTemp, 25.0)
    }

    func testUpdateBarometric() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .barometric, value: 101.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.barometric, 101.0)
    }

    func testUpdateDistance() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .distance, value: 150.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.distance, 150.0)
    }

    func testUpdateRuntime() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .runtime, value: 3600.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.runtime, 3600.0)
    }

    func testUpdateEngineFuelRate() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .engineFuelRate, value: 5.5)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.engineFuelRate, 5.5)
    }

    func testUpdateEngineTorquePercentage() {
        var diagnostics = VehicleDiagnostics()
        let reading = DiagnosticReading(pid: .engineTorquePercentage, value: 80.0)

        diagnostics.update(with: reading)

        XCTAssertEqual(diagnostics.engineTorquePercentage, 80.0)
    }

    // MARK: - Invalid Reading Handling

    func testInvalidReadingIgnored() {
        var diagnostics = VehicleDiagnostics()
        let invalidReading = DiagnosticReading(pid: .speed, value: -10.0)

        diagnostics.update(with: invalidReading)

        XCTAssertNil(diagnostics.speed)
    }

    func testExceedsMaxValueIgnored() {
        var diagnostics = VehicleDiagnostics()
        let invalidReading = DiagnosticReading(pid: .speed, value: 2000.0)

        diagnostics.update(with: invalidReading)

        XCTAssertNil(diagnostics.speed)
    }

    // MARK: - Update with Packet

    func testUpdateWithPacket() {
        var diagnostics = VehicleDiagnostics()
        let packet = BLEDataPacket(
            time: 12345,
            pid: OBDPID.speed.rawValue,
            flags: 0,
            checksum: 0,
            values: (65.0, 0, 0)
        )

        diagnostics.update(with: packet)

        XCTAssertEqual(diagnostics.speed, 65.0)
    }

    func testUpdateWithUnknownPIDPacketIgnored() {
        var diagnostics = VehicleDiagnostics()
        let packet = BLEDataPacket(
            time: 12345,
            pid: 0xFFFF,  // Unknown PID
            flags: 0,
            checksum: 0,
            values: (65.0, 0, 0)
        )

        diagnostics.update(with: packet)

        // All values should still be nil
        XCTAssertNil(diagnostics.speed)
        XCTAssertNil(diagnostics.rpm)
    }

    // MARK: - Timestamp Updates

    func testTimestampUpdatesOnValidReading() {
        var diagnostics = VehicleDiagnostics()
        let initialTime = diagnostics.lastUpdated

        // Small delay to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)

        let reading = DiagnosticReading(pid: .speed, value: 65.0)
        diagnostics.update(with: reading)

        XCTAssertGreaterThan(diagnostics.lastUpdated, initialTime)
    }

    func testTimestampDoesNotUpdateOnInvalidReading() {
        var diagnostics = VehicleDiagnostics()
        let initialTime = diagnostics.lastUpdated

        let invalidReading = DiagnosticReading(pid: .speed, value: -10.0)
        diagnostics.update(with: invalidReading)

        XCTAssertEqual(diagnostics.lastUpdated, initialTime)
    }

    // MARK: - Multiple Updates

    func testMultipleUpdates() {
        var diagnostics = VehicleDiagnostics()

        diagnostics.update(with: DiagnosticReading(pid: .speed, value: 60.0))
        diagnostics.update(with: DiagnosticReading(pid: .rpm, value: 2500.0))
        diagnostics.update(with: DiagnosticReading(pid: .fuelLevel, value: 80.0))
        diagnostics.update(with: DiagnosticReading(pid: .coolantTemp, value: 85.0))

        XCTAssertEqual(diagnostics.speed, 60.0)
        XCTAssertEqual(diagnostics.rpm, 2500.0)
        XCTAssertEqual(diagnostics.fuelLevel, 80.0)
        XCTAssertEqual(diagnostics.coolantTemp, 85.0)
    }

    func testOverwritePreviousValue() {
        var diagnostics = VehicleDiagnostics()

        diagnostics.update(with: DiagnosticReading(pid: .speed, value: 60.0))
        XCTAssertEqual(diagnostics.speed, 60.0)

        diagnostics.update(with: DiagnosticReading(pid: .speed, value: 70.0))
        XCTAssertEqual(diagnostics.speed, 70.0)
    }
}

// MARK: - Accelerometer Reading Tests

final class AccelerometerReadingTests: XCTestCase {

    func testInitialization() {
        let reading = AccelerometerReading(x: 0.1, y: 0.2, z: 0.3)

        XCTAssertEqual(reading.x, 0.1)
        XCTAssertEqual(reading.y, 0.2)
        XCTAssertEqual(reading.z, 0.3)
        XCTAssertNotNil(reading.timestamp)
    }

    func testInitializationWithTimestamp() {
        let date = Date(timeIntervalSince1970: 1000)
        let reading = AccelerometerReading(x: 1.0, y: 0.0, z: 0.0, timestamp: date)

        XCTAssertEqual(reading.timestamp, date)
    }

    func testMagnitudeSimple() {
        // (3, 4, 0) should have magnitude 5
        let reading = AccelerometerReading(x: 3.0, y: 4.0, z: 0.0)
        XCTAssertEqual(reading.magnitude, 5.0, accuracy: 0.001)
    }

    func testMagnitude3D() {
        // (1, 2, 2) should have magnitude 3
        let reading = AccelerometerReading(x: 1.0, y: 2.0, z: 2.0)
        XCTAssertEqual(reading.magnitude, 3.0, accuracy: 0.001)
    }

    func testMagnitudeZero() {
        let reading = AccelerometerReading(x: 0.0, y: 0.0, z: 0.0)
        XCTAssertEqual(reading.magnitude, 0.0)
    }

    func testMagnitudeWithNegatives() {
        // (-3, -4, 0) should also have magnitude 5
        let reading = AccelerometerReading(x: -3.0, y: -4.0, z: 0.0)
        XCTAssertEqual(reading.magnitude, 5.0, accuracy: 0.001)
    }
}
