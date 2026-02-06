//
//  BLETypes.swift
//  vBox
//
//  Swift types for Bluetooth Low Energy management
//

import Foundation
import CoreBluetooth

// MARK: - BLE State

/// Represents the current state of the Bluetooth adapter
enum BLEState: Int, CustomStringConvertible {
    case unknown = 0
    case resetting = 1
    case unsupported = 2
    case unauthorized = 3
    case off = 4
    case on = 5

    /// Initialize from CoreBluetooth manager state
    init(from cbState: CBManagerState) {
        switch cbState {
        case .unknown: self = .unknown
        case .resetting: self = .resetting
        case .unsupported: self = .unsupported
        case .unauthorized: self = .unauthorized
        case .poweredOff: self = .off
        case .poweredOn: self = .on
        @unknown default: self = .unknown
        }
    }

    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .off: return "Off"
        case .on: return "On"
        }
    }

    /// Whether Bluetooth is ready for scanning/connecting
    var isReady: Bool {
        return self == .on
    }

    /// Whether there's an issue that needs user attention
    var requiresUserAction: Bool {
        switch self {
        case .unsupported, .unauthorized, .off:
            return true
        default:
            return false
        }
    }

    /// User-friendly message describing the state
    var userMessage: String {
        switch self {
        case .unknown:
            return "Bluetooth status is unknown"
        case .resetting:
            return "Bluetooth is resetting..."
        case .unsupported:
            return "This device does not support Bluetooth Low Energy"
        case .unauthorized:
            return "Please authorize Bluetooth access in Settings"
        case .off:
            return "Please turn on Bluetooth in Settings"
        case .on:
            return "Bluetooth is ready"
        }
    }
}

// MARK: - Peripheral Type

/// Types of peripherals the app can connect to
enum PeripheralType: String, CaseIterable {
    case obdAdapter = "OBD"
    case beagleBone = "BeagleBone"

    /// The BLE service UUID to scan for
    var serviceUUID: CBUUID {
        switch self {
        case .obdAdapter:
            return CBUUID(string: "FFE0")
        case .beagleBone:
            return CBUUID(string: "FFEF")
        }
    }

    /// The characteristic UUID for data transfer
    var characteristicUUID: CBUUID {
        return CBUUID(string: "FFE1")
    }
}

// MARK: - Connection State

/// Represents the connection state of a peripheral
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting

    /// Initialize from CoreBluetooth peripheral state
    init(from cbState: CBPeripheralState) {
        switch cbState {
        case .disconnected: self = .disconnected
        case .connecting: self = .connecting
        case .connected: self = .connected
        case .disconnecting: self = .disconnecting
        @unknown default: self = .disconnected
        }
    }

    var isConnected: Bool {
        return self == .connected
    }
}

// MARK: - Discovered Peripheral

/// Information about a discovered BLE peripheral
struct DiscoveredPeripheral {
    let identifier: UUID
    let name: String?
    let rssi: Int
    let advertisementData: [String: Any]
    let discoveredAt: Date

    init(peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]) {
        self.identifier = peripheral.identifier
        self.name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.rssi = rssi.intValue
        self.advertisementData = advertisementData
        self.discoveredAt = Date()
    }

    /// Display name for the peripheral
    var displayName: String {
        return name ?? "Unknown Device"
    }

    /// Signal strength description
    var signalStrength: SignalStrength {
        return SignalStrength(rssi: rssi)
    }
}

// MARK: - Signal Strength

/// Categorization of BLE signal strength
enum SignalStrength: CustomStringConvertible {
    case excellent  // > -50 dBm
    case good       // -50 to -70 dBm
    case fair       // -70 to -80 dBm
    case weak       // < -80 dBm

    init(rssi: Int) {
        switch rssi {
        case -50...: self = .excellent
        case -70 ..< -50: self = .good
        case -80 ..< -70: self = .fair
        default: self = .weak
        }
    }

    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .weak: return "Weak"
        }
    }

    /// Number of bars to show (0-4)
    var bars: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .weak: return 1
        }
    }
}

// MARK: - BLE Error

/// Errors that can occur during BLE operations
enum BLEError: LocalizedError {
    case bluetoothOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
    case notConnected
    case connectionFailed(Error?)
    case serviceNotFound
    case characteristicNotFound
    case writeError(Error?)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .bluetoothOff:
            return "Bluetooth is turned off"
        case .bluetoothUnauthorized:
            return "Bluetooth access is not authorized"
        case .bluetoothUnsupported:
            return "Bluetooth Low Energy is not supported on this device"
        case .notConnected:
            return "Not connected to a device"
        case .connectionFailed(let error):
            return "Connection failed: \(error?.localizedDescription ?? "Unknown error")"
        case .serviceNotFound:
            return "Required BLE service not found"
        case .characteristicNotFound:
            return "Required BLE characteristic not found"
        case .writeError(let error):
            return "Failed to write data: \(error?.localizedDescription ?? "Unknown error")"
        case .invalidData:
            return "Received invalid data"
        }
    }
}

// MARK: - BLE Manager Delegate Protocol

/// Protocol for receiving BLE manager updates
protocol BLEManagerDelegate: AnyObject {
    /// Called when Bluetooth state changes
    func bleManager(_ manager: Any, didUpdateState state: BLEState)

    /// Called when a peripheral is discovered
    func bleManager(_ manager: Any, didDiscover peripheral: DiscoveredPeripheral)

    /// Called when connected to a peripheral
    func bleManager(_ manager: Any, didConnect peripheral: DiscoveredPeripheral)

    /// Called when disconnected from a peripheral
    func bleManager(_ manager: Any, didDisconnect peripheral: DiscoveredPeripheral, error: Error?)

    /// Called when a diagnostic value is received
    func bleManager(_ manager: Any, didReceive reading: DiagnosticReading)

    /// Called for debug logging
    func bleManager(_ manager: Any, didLog message: String)
}

// MARK: - Default Implementations

extension BLEManagerDelegate {
    func bleManager(_ manager: Any, didDiscover peripheral: DiscoveredPeripheral) {}
    func bleManager(_ manager: Any, didConnect peripheral: DiscoveredPeripheral) {}
    func bleManager(_ manager: Any, didDisconnect peripheral: DiscoveredPeripheral, error: Error?) {}
    func bleManager(_ manager: Any, didReceive reading: DiagnosticReading) {}
    func bleManager(_ manager: Any, didLog message: String) {}
}
