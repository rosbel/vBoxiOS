//
//  BLEManagerSwiftTests.swift
//  vBoxTests
//
//  Tests for BLEManagerSwift
//

import XCTest
import CoreBluetooth
import Combine
@testable import vBox

// MARK: - BLE Manager Tests

final class BLEManagerSwiftTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSharedInstanceExists() {
        let manager = BLEManagerSwift.shared
        XCTAssertNotNil(manager)
    }

    func testSharedInstanceIsSingleton() {
        let manager1 = BLEManagerSwift.shared
        let manager2 = BLEManagerSwift.shared
        XCTAssertTrue(manager1 === manager2)
    }

    func testInitialStateIsNotConnected() {
        let manager = BLEManagerSwift()
        XCTAssertFalse(manager.isConnected)
    }

    func testInitialStateIsNotScanning() {
        let manager = BLEManagerSwift()
        XCTAssertFalse(manager.isScanning)
    }

    func testInitialDiagnosticsAreEmpty() {
        let manager = BLEManagerSwift()
        XCTAssertNil(manager.diagnostics.speed)
        XCTAssertNil(manager.diagnostics.rpm)
        XCTAssertNil(manager.diagnostics.fuelLevel)
    }

    // MARK: - State Publisher Tests

    func testStatePublisherEmitsValues() {
        let manager = BLEManagerSwift()
        let expectation = XCTestExpectation(description: "State publisher emits")

        manager.statePublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Connection Publisher Tests

    func testConnectionPublisherEmitsInitialFalse() {
        let manager = BLEManagerSwift()
        let expectation = XCTestExpectation(description: "Connection publisher emits false")

        manager.connectionPublisher
            .first()
            .sink { isConnected in
                XCTAssertFalse(isConnected)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Scan Tests

    func testScanFailsWhenBluetoothNotReady() {
        let manager = BLEManagerSwift()
        // State is initially unknown, not .on
        let result = manager.scan(for: .obdAdapter)
        XCTAssertFalse(result)
    }

    // MARK: - Peripheral Type Tests

    func testOBDAdapterPeripheralType() {
        let type = PeripheralType.obdAdapter
        XCTAssertEqual(type.serviceUUID, CBUUID(string: "FFE0"))
    }

    func testBeagleBonePeripheralType() {
        let type = PeripheralType.beagleBone
        XCTAssertEqual(type.serviceUUID, CBUUID(string: "FFEF"))
    }
}

// MARK: - BLE Manager Delegate Tests

final class BLEManagerDelegateTests: XCTestCase {

    // MARK: - Mock Delegate

    class MockDelegate: BLEManagerSwiftDelegate {
        var stateChanges: [BLEState] = []
        var diagnosticUpdates: [(key: String, value: NSNumber)] = []
        var didBeginScanningCalled = false
        var didStopScanningCalled = false
        var didConnectCalled = false
        var didDisconnectCalled = false
        var logMessages: [String] = []

        func bleManager(_ manager: BLEManagerSwift, didChangeState state: BLEState) {
            stateChanges.append(state)
        }

        func bleManager(_ manager: BLEManagerSwift, didUpdateDiagnostic key: String, value: NSNumber) {
            diagnosticUpdates.append((key: key, value: value))
        }

        func bleManagerDidBeginScanning(_ manager: BLEManagerSwift) {
            didBeginScanningCalled = true
        }

        func bleManagerDidStopScanning(_ manager: BLEManagerSwift) {
            didStopScanningCalled = true
        }

        func bleManagerDidConnect(_ manager: BLEManagerSwift) {
            didConnectCalled = true
        }

        func bleManagerDidDisconnect(_ manager: BLEManagerSwift) {
            didDisconnectCalled = true
        }

        func bleManager(_ manager: BLEManagerSwift, didLogMessage message: String) {
            logMessages.append(message)
        }
    }

    func testDelegateCanBeSet() {
        let manager = BLEManagerSwift()
        let delegate = MockDelegate()
        manager.delegate = delegate
        XCTAssertNotNil(manager.delegate)
    }

    func testDelegateIsWeakReference() {
        let manager = BLEManagerSwift()

        autoreleasepool {
            let delegate = MockDelegate()
            manager.delegate = delegate
            XCTAssertNotNil(manager.delegate)
        }

        // After autorelease, delegate should be nil (weak reference)
        XCTAssertNil(manager.delegate)
    }
}

// MARK: - Combine Integration Tests

final class BLEManagerCombineTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    func testSpeedPublisherExists() {
        let manager = BLEManagerSwift()
        let publisher = manager.speedPublisher

        let expectation = XCTestExpectation(description: "Speed publisher emits")

        publisher
            .first()
            .sink { speed in
                XCTAssertNil(speed) // Initially nil
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testRPMPublisherExists() {
        let manager = BLEManagerSwift()
        let publisher = manager.rpmPublisher

        let expectation = XCTestExpectation(description: "RPM publisher emits")

        publisher
            .first()
            .sink { rpm in
                XCTAssertNil(rpm) // Initially nil
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testFuelLevelPublisherExists() {
        let manager = BLEManagerSwift()
        let publisher = manager.fuelLevelPublisher

        let expectation = XCTestExpectation(description: "Fuel publisher emits")

        publisher
            .first()
            .sink { fuel in
                XCTAssertNil(fuel) // Initially nil
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testDiagnosticsPublisherExists() {
        let manager = BLEManagerSwift()
        let publisher = manager.diagnosticsPublisher

        let expectation = XCTestExpectation(description: "Diagnostics publisher emits")

        publisher
            .first()
            .sink { diagnostics in
                XCTAssertNotNil(diagnostics)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Data Processing Tests

final class BLEDataProcessingTests: XCTestCase {

    func testValidPacketCreation() {
        let data = TestBLEDataBuilder.speedPacket(value: 65.0)
        XCTAssertEqual(data.count, 12)
    }

    func testRPMPacketCreation() {
        let data = TestBLEDataBuilder.rpmPacket(value: 3000.0)
        XCTAssertEqual(data.count, 12)
    }

    func testFuelPacketCreation() {
        let data = TestBLEDataBuilder.fuelPacket(value: 75.0)
        XCTAssertEqual(data.count, 12)
    }
}
