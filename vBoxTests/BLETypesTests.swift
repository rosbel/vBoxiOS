//
//  BLETypesTests.swift
//  vBoxTests
//
//  Tests for Bluetooth Low Energy types
//

import XCTest
import CoreBluetooth
@testable import vBox

// MARK: - BLE State Tests

final class BLEStateTests: XCTestCase {

    // MARK: - Raw Values (matching Obj-C BLEState enum)

    func testRawValues() {
        XCTAssertEqual(BLEState.unknown.rawValue, 0)
        XCTAssertEqual(BLEState.resetting.rawValue, 1)
        XCTAssertEqual(BLEState.unsupported.rawValue, 2)
        XCTAssertEqual(BLEState.unauthorized.rawValue, 3)
        XCTAssertEqual(BLEState.off.rawValue, 4)
        XCTAssertEqual(BLEState.on.rawValue, 5)
    }

    // MARK: - Description

    func testDescriptions() {
        XCTAssertEqual(BLEState.unknown.description, "Unknown")
        XCTAssertEqual(BLEState.resetting.description, "Resetting")
        XCTAssertEqual(BLEState.unsupported.description, "Unsupported")
        XCTAssertEqual(BLEState.unauthorized.description, "Unauthorized")
        XCTAssertEqual(BLEState.off.description, "Off")
        XCTAssertEqual(BLEState.on.description, "On")
    }

    // MARK: - isReady

    func testIsReadyOnlyWhenOn() {
        XCTAssertFalse(BLEState.unknown.isReady)
        XCTAssertFalse(BLEState.resetting.isReady)
        XCTAssertFalse(BLEState.unsupported.isReady)
        XCTAssertFalse(BLEState.unauthorized.isReady)
        XCTAssertFalse(BLEState.off.isReady)
        XCTAssertTrue(BLEState.on.isReady)
    }

    // MARK: - requiresUserAction

    func testRequiresUserActionForIssues() {
        XCTAssertFalse(BLEState.unknown.requiresUserAction)
        XCTAssertFalse(BLEState.resetting.requiresUserAction)
        XCTAssertTrue(BLEState.unsupported.requiresUserAction)
        XCTAssertTrue(BLEState.unauthorized.requiresUserAction)
        XCTAssertTrue(BLEState.off.requiresUserAction)
        XCTAssertFalse(BLEState.on.requiresUserAction)
    }

    // MARK: - User Messages

    func testUserMessages() {
        XCTAssertFalse(BLEState.unknown.userMessage.isEmpty)
        XCTAssertFalse(BLEState.resetting.userMessage.isEmpty)
        XCTAssertFalse(BLEState.unsupported.userMessage.isEmpty)
        XCTAssertFalse(BLEState.unauthorized.userMessage.isEmpty)
        XCTAssertFalse(BLEState.off.userMessage.isEmpty)
        XCTAssertFalse(BLEState.on.userMessage.isEmpty)
    }
}

// MARK: - Peripheral Type Tests

final class PeripheralTypeTests: XCTestCase {

    func testOBDAdapterServiceUUID() {
        let expected = CBUUID(string: "FFE0")
        XCTAssertEqual(PeripheralType.obdAdapter.serviceUUID, expected)
    }

    func testBeagleBoneServiceUUID() {
        let expected = CBUUID(string: "FFEF")
        XCTAssertEqual(PeripheralType.beagleBone.serviceUUID, expected)
    }

    func testCharacteristicUUID() {
        let expected = CBUUID(string: "FFE1")
        XCTAssertEqual(PeripheralType.obdAdapter.characteristicUUID, expected)
        XCTAssertEqual(PeripheralType.beagleBone.characteristicUUID, expected)
    }

    func testAllCases() {
        XCTAssertEqual(PeripheralType.allCases.count, 2)
        XCTAssertTrue(PeripheralType.allCases.contains(.obdAdapter))
        XCTAssertTrue(PeripheralType.allCases.contains(.beagleBone))
    }

    func testRawValues() {
        XCTAssertEqual(PeripheralType.obdAdapter.rawValue, "OBD")
        XCTAssertEqual(PeripheralType.beagleBone.rawValue, "BeagleBone")
    }
}

// MARK: - Connection State Tests

final class ConnectionStateTests: XCTestCase {

    func testIsConnectedOnlyWhenConnected() {
        XCTAssertFalse(ConnectionState.disconnected.isConnected)
        XCTAssertFalse(ConnectionState.connecting.isConnected)
        XCTAssertTrue(ConnectionState.connected.isConnected)
        XCTAssertFalse(ConnectionState.disconnecting.isConnected)
    }
}

// MARK: - Signal Strength Tests

final class SignalStrengthTests: XCTestCase {

    func testExcellentSignal() {
        XCTAssertEqual(SignalStrength(rssi: -30), .excellent)
        XCTAssertEqual(SignalStrength(rssi: -49), .excellent)
        XCTAssertEqual(SignalStrength(rssi: -50), .excellent)
    }

    func testGoodSignal() {
        XCTAssertEqual(SignalStrength(rssi: -51), .good)
        XCTAssertEqual(SignalStrength(rssi: -60), .good)
        XCTAssertEqual(SignalStrength(rssi: -69), .good)
    }

    func testFairSignal() {
        XCTAssertEqual(SignalStrength(rssi: -70), .fair)
        XCTAssertEqual(SignalStrength(rssi: -75), .fair)
        XCTAssertEqual(SignalStrength(rssi: -79), .fair)
    }

    func testWeakSignal() {
        XCTAssertEqual(SignalStrength(rssi: -80), .weak)
        XCTAssertEqual(SignalStrength(rssi: -90), .weak)
        XCTAssertEqual(SignalStrength(rssi: -100), .weak)
    }

    func testBars() {
        XCTAssertEqual(SignalStrength.excellent.bars, 4)
        XCTAssertEqual(SignalStrength.good.bars, 3)
        XCTAssertEqual(SignalStrength.fair.bars, 2)
        XCTAssertEqual(SignalStrength.weak.bars, 1)
    }

    func testDescriptions() {
        XCTAssertEqual(SignalStrength.excellent.description, "Excellent")
        XCTAssertEqual(SignalStrength.good.description, "Good")
        XCTAssertEqual(SignalStrength.fair.description, "Fair")
        XCTAssertEqual(SignalStrength.weak.description, "Weak")
    }
}

// MARK: - BLE Error Tests

final class BLEErrorTests: XCTestCase {

    func testBluetoothOffDescription() {
        let error = BLEError.bluetoothOff
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("off"))
    }

    func testBluetoothUnauthorizedDescription() {
        let error = BLEError.bluetoothUnauthorized
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("unauthorized"))
    }

    func testBluetoothUnsupportedDescription() {
        let error = BLEError.bluetoothUnsupported
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("not supported"))
    }

    func testNotConnectedDescription() {
        let error = BLEError.notConnected
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("not connected"))
    }

    func testConnectionFailedWithError() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = BLEError.connectionFailed(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Test error"))
    }

    func testConnectionFailedWithoutError() {
        let error = BLEError.connectionFailed(nil)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("unknown"))
    }

    func testServiceNotFoundDescription() {
        let error = BLEError.serviceNotFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("service"))
    }

    func testCharacteristicNotFoundDescription() {
        let error = BLEError.characteristicNotFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("characteristic"))
    }

    func testWriteErrorWithError() {
        let underlyingError = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Write failed"])
        let error = BLEError.writeError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Write failed"))
    }

    func testInvalidDataDescription() {
        let error = BLEError.invalidData
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("invalid"))
    }
}

// MARK: - Discovered Peripheral Tests

final class DiscoveredPeripheralTests: XCTestCase {

    func testDisplayNameWithName() {
        // We can't easily create a mock CBPeripheral, so we'll test the simpler paths
        // Testing the type's logic directly
        let peripheral = DiscoveredPeripheral(
            identifier: UUID(),
            name: "Test Device",
            rssi: -50,
            advertisementData: [:],
            discoveredAt: Date()
        )
        XCTAssertEqual(peripheral.displayName, "Test Device")
    }

    func testDisplayNameWithoutName() {
        let peripheral = DiscoveredPeripheral(
            identifier: UUID(),
            name: nil,
            rssi: -50,
            advertisementData: [:],
            discoveredAt: Date()
        )
        XCTAssertEqual(peripheral.displayName, "Unknown Device")
    }

    func testSignalStrengthMapping() {
        let excellentPeripheral = DiscoveredPeripheral(
            identifier: UUID(),
            name: "Test",
            rssi: -40,
            advertisementData: [:],
            discoveredAt: Date()
        )
        XCTAssertEqual(excellentPeripheral.signalStrength, .excellent)

        let weakPeripheral = DiscoveredPeripheral(
            identifier: UUID(),
            name: "Test",
            rssi: -90,
            advertisementData: [:],
            discoveredAt: Date()
        )
        XCTAssertEqual(weakPeripheral.signalStrength, .weak)
    }
}

// MARK: - Helper extension for testing DiscoveredPeripheral without CBPeripheral

extension DiscoveredPeripheral {
    /// Test initializer without requiring CBPeripheral
    init(identifier: UUID, name: String?, rssi: Int, advertisementData: [String: Any], discoveredAt: Date) {
        self.identifier = identifier
        self.name = name
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.discoveredAt = discoveredAt
    }
}
