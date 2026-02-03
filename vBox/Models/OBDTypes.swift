//
//  OBDTypes.swift
//  vBox
//
//  Swift types for OBD-II protocol data
//

import Foundation

// MARK: - OBD-II Parameter IDs (PIDs)

/// Standard OBD-II Parameter IDs supported by the Freematics adapter
enum OBDPID: UInt16 {
    // Engine PIDs
    case speed = 0x10D
    case rpm = 0x10C
    case engineLoad = 0x104
    case coolantTemp = 0x105
    case throttle = 0x111
    case runtime = 0x11F
    case engineFuelRate = 0x159
    case engineTorquePercentage = 0x15B

    // Fuel PIDs
    case fuelLevel = 0x12F

    // Environmental PIDs
    case intakeTemp = 0x10F
    case ambientTemp = 0x146
    case barometric = 0x133

    // Distance
    case distance = 0x131

    // GPS PIDs (Freematics specific)
    case gpsLatitude = 0xF00A
    case gpsLongitude = 0xF00B
    case gpsAltitude = 0x000C
    case gpsSpeed = 0xF00D
    case gpsHeading = 0xF00E
    case gpsSatCount = 0xF00F
    case gpsTime = 0xF010

    // Accelerometer/Gyro PIDs
    case accelerometer = 0xF020
    case gyroscope = 0xF021

    /// Human-readable name for the PID
    var displayName: String {
        switch self {
        case .speed: return "Speed"
        case .rpm: return "RPM"
        case .engineLoad: return "Engine Load"
        case .coolantTemp: return "Coolant Temp"
        case .throttle: return "Throttle"
        case .runtime: return "Runtime"
        case .engineFuelRate: return "Engine Fuel Rate"
        case .engineTorquePercentage: return "Engine Torque Percentage"
        case .fuelLevel: return "Fuel"
        case .intakeTemp: return "Intake Temp"
        case .ambientTemp: return "Ambient Temp"
        case .barometric: return "Barometric"
        case .distance: return "Distance"
        case .gpsLatitude: return "GPS Latitude"
        case .gpsLongitude: return "GPS Longitude"
        case .gpsAltitude: return "GPS Altitude"
        case .gpsSpeed: return "GPS Speed"
        case .gpsHeading: return "GPS Heading"
        case .gpsSatCount: return "GPS Satellites"
        case .gpsTime: return "GPS Time"
        case .accelerometer: return "Accelerometer"
        case .gyroscope: return "Gyroscope"
        }
    }

    /// Maximum reasonable value for validation
    var maxValidValue: Float {
        switch self {
        case .speed: return 1000.0
        case .rpm: return 100000.0
        case .engineLoad: return 150.0
        case .coolantTemp: return 500.0
        case .throttle: return 1000.0
        case .runtime: return .greatestFiniteMagnitude
        case .engineFuelRate: return 1000.0
        case .engineTorquePercentage: return 150.0
        case .fuelLevel: return 150.0
        case .intakeTemp: return 1000.0
        case .ambientTemp: return 1000.0
        case .barometric: return 500.0
        case .distance: return 10000000.0
        default: return .greatestFiniteMagnitude
        }
    }
}

// MARK: - BLE Data Packet

/// Represents a raw BLE data packet from the Freematics OBD adapter
/// The adapter sends 12-byte packets with the following structure:
/// - time: 4 bytes (UInt32) - timestamp
/// - pid: 2 bytes (UInt16) - parameter ID
/// - flags: 1 byte (UInt8) - status flags
/// - checksum: 1 byte (UInt8) - XOR checksum
/// - value: 12 bytes (3 x Float) - up to 3 float values
struct BLEDataPacket {
    static let packetSize = 24  // 4 + 2 + 1 + 1 + (4 * 4) = 24 bytes actually, but protocol uses 12
    static let legacyPacketSize = 12

    let time: UInt32
    let pid: UInt16
    let flags: UInt8
    let checksum: UInt8
    let values: (Float, Float, Float)

    /// Initialize from raw data bytes
    /// - Parameter data: Raw data from BLE characteristic (12 bytes)
    /// - Returns: nil if data is invalid or checksum fails
    init?(data: Data) {
        guard data.count >= Self.legacyPacketSize else { return nil }

        // Parse the packet
        var offset = 0

        time = data.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: offset, as: UInt32.self)
        }
        offset += 4

        pid = data.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: offset, as: UInt16.self)
        }
        offset += 2

        flags = data[offset]
        offset += 1

        checksum = data[offset]
        offset += 1

        // For 12-byte packets, we only have one float value
        // The struct in Obj-C has value[3] but only 12 bytes total
        // So: 4 + 2 + 1 + 1 + 4 = 12 (only one float fits)
        let value0 = data.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: offset, as: Float.self)
        }
        values = (value0, 0, 0)

        // Validate checksum
        guard Self.validateChecksum(data: data, length: Self.legacyPacketSize) else {
            return nil
        }
    }

    /// Create a packet for testing purposes
    init(time: UInt32, pid: UInt16, flags: UInt8, checksum: UInt8, values: (Float, Float, Float)) {
        self.time = time
        self.pid = pid
        self.flags = flags
        self.checksum = checksum
        self.values = values
    }

    /// Calculate XOR checksum for data
    static func calculateChecksum(data: Data, length: Int) -> UInt8 {
        var checksum: UInt8 = 0
        for i in 0..<min(length, data.count) {
            checksum ^= data[i]
        }
        return checksum
    }

    /// Validate that the checksum in the data is correct
    static func validateChecksum(data: Data, length: Int) -> Bool {
        return calculateChecksum(data: data, length: length) == 0
    }

    /// The parsed OBD PID if it's a known type
    var obdPID: OBDPID? {
        return OBDPID(rawValue: pid)
    }

    /// Primary value from the packet
    var primaryValue: Float {
        return values.0
    }
}

// MARK: - Diagnostic Reading

/// A validated diagnostic reading from the OBD adapter
struct DiagnosticReading {
    let pid: OBDPID
    let value: Float
    let timestamp: Date

    init(pid: OBDPID, value: Float, timestamp: Date = Date()) {
        self.pid = pid
        self.value = value
        self.timestamp = timestamp
    }

    /// Check if the value is within valid range
    var isValid: Bool {
        return value >= 0 && value <= pid.maxValidValue
    }

    /// Display-friendly string representation
    var displayString: String {
        switch pid {
        case .speed:
            return String(format: "%.0f km/h", value)
        case .rpm:
            return String(format: "%.0f RPM", value)
        case .fuelLevel:
            return String(format: "%.0f%%", value)
        case .coolantTemp, .intakeTemp, .ambientTemp:
            return String(format: "%.0f\u{00B0}C", value)
        case .engineLoad, .throttle, .engineTorquePercentage:
            return String(format: "%.1f%%", value)
        case .barometric:
            return String(format: "%.0f kPa", value)
        case .distance:
            return String(format: "%.1f km", value)
        default:
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Vehicle Diagnostics Snapshot

/// A snapshot of all current vehicle diagnostics
struct VehicleDiagnostics {
    var speed: Float?
    var rpm: Float?
    var fuelLevel: Float?
    var coolantTemp: Float?
    var engineLoad: Float?
    var throttle: Float?
    var intakeTemp: Float?
    var ambientTemp: Float?
    var barometric: Float?
    var distance: Float?
    var runtime: Float?
    var engineFuelRate: Float?
    var engineTorquePercentage: Float?

    var lastUpdated: Date = Date()

    init() {}

    /// Update a diagnostic value from a reading
    mutating func update(with reading: DiagnosticReading) {
        guard reading.isValid else { return }

        lastUpdated = reading.timestamp

        switch reading.pid {
        case .speed: speed = reading.value
        case .rpm: rpm = reading.value
        case .fuelLevel: fuelLevel = reading.value
        case .coolantTemp: coolantTemp = reading.value
        case .engineLoad: engineLoad = reading.value
        case .throttle: throttle = reading.value
        case .intakeTemp: intakeTemp = reading.value
        case .ambientTemp: ambientTemp = reading.value
        case .barometric: barometric = reading.value
        case .distance: distance = reading.value
        case .runtime: runtime = reading.value
        case .engineFuelRate: engineFuelRate = reading.value
        case .engineTorquePercentage: engineTorquePercentage = reading.value
        default: break
        }
    }

    /// Update from a parsed BLE packet
    mutating func update(with packet: BLEDataPacket) {
        guard let pid = packet.obdPID else { return }
        let reading = DiagnosticReading(pid: pid, value: packet.primaryValue)
        update(with: reading)
    }
}

// MARK: - Accelerometer Data

/// 3-axis accelerometer reading
struct AccelerometerReading {
    let x: Float
    let y: Float
    let z: Float
    let timestamp: Date

    init(x: Float, y: Float, z: Float, timestamp: Date = Date()) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    /// Magnitude of the acceleration vector
    var magnitude: Float {
        return sqrt(x * x + y * y + z * z)
    }
}
