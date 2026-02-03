//
//  BluetoothDataEntity.swift
//  vBox
//
//  Swift Core Data model for BluetoothData entity
//

import Foundation
import CoreData

// MARK: - Bluetooth Data Entity

@objc(BluetoothDataEntity)
public class BluetoothDataEntity: NSManagedObject {

    // MARK: - Core Data Properties

    @NSManaged public var speed: NSNumber?
    @NSManaged public var rpm: NSNumber?
    @NSManaged public var fuel: NSNumber?
    @NSManaged public var coolantTemp: NSNumber?
    @NSManaged public var engineLoad: NSNumber?
    @NSManaged public var throttle: NSNumber?
    @NSManaged public var intakeTemp: NSNumber?
    @NSManaged public var ambientTemp: NSNumber?
    @NSManaged public var barometric: NSNumber?
    @NSManaged public var distance: NSNumber?
    @NSManaged public var accelX: NSNumber?
    @NSManaged public var accelY: NSNumber?
    @NSManaged public var accelZ: NSNumber?
    @NSManaged public var location: GPSLocationEntity?
}

// MARK: - Fetch Request

extension BluetoothDataEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BluetoothDataEntity> {
        return NSFetchRequest<BluetoothDataEntity>(entityName: "BluetoothData")
    }
}

// MARK: - Computed Properties

extension BluetoothDataEntity {

    // MARK: Speed & Engine

    /// OBD speed in km/h
    var speedKmh: Double? {
        return speed?.doubleValue
    }

    /// OBD speed in mph
    var speedMph: Double? {
        guard let kmh = speedKmh else { return nil }
        return kmh * 0.621371
    }

    /// Engine RPM
    var engineRpm: Double? {
        return rpm?.doubleValue
    }

    /// Engine load percentage (0-100)
    var engineLoadPercentage: Double? {
        return engineLoad?.doubleValue
    }

    /// Throttle position percentage (0-100)
    var throttlePosition: Double? {
        return throttle?.doubleValue
    }

    // MARK: Fuel

    /// Fuel level percentage (0-100)
    var fuelLevel: Double? {
        return fuel?.doubleValue
    }

    /// Whether fuel is low (below 15%)
    var isFuelLow: Bool {
        guard let level = fuelLevel else { return false }
        return level < 15
    }

    // MARK: Temperatures

    /// Coolant temperature in Celsius
    var coolantTemperature: Double? {
        return coolantTemp?.doubleValue
    }

    /// Coolant temperature in Fahrenheit
    var coolantTemperatureFahrenheit: Double? {
        guard let celsius = coolantTemperature else { return nil }
        return celsius * 9/5 + 32
    }

    /// Intake air temperature in Celsius
    var intakeTemperature: Double? {
        return intakeTemp?.doubleValue
    }

    /// Ambient temperature in Celsius
    var ambientTemperature: Double? {
        return ambientTemp?.doubleValue
    }

    /// Whether engine is overheating (coolant > 105°C)
    var isOverheating: Bool {
        guard let temp = coolantTemperature else { return false }
        return temp > 105
    }

    /// Whether engine is at normal operating temperature (80-100°C)
    var isAtOperatingTemperature: Bool {
        guard let temp = coolantTemperature else { return false }
        return temp >= 80 && temp <= 100
    }

    // MARK: Pressure

    /// Barometric pressure in kPa
    var barometricPressure: Double? {
        return barometric?.doubleValue
    }

    // MARK: Distance

    /// OBD distance traveled
    var distanceTraveled: Double? {
        return distance?.doubleValue
    }

    // MARK: Accelerometer

    /// X-axis acceleration
    var accelerationX: Double? {
        return accelX?.doubleValue
    }

    /// Y-axis acceleration
    var accelerationY: Double? {
        return accelY?.doubleValue
    }

    /// Z-axis acceleration
    var accelerationZ: Double? {
        return accelZ?.doubleValue
    }

    /// Total acceleration magnitude
    var accelerationMagnitude: Double? {
        guard let x = accelerationX,
              let y = accelerationY,
              let z = accelerationZ else {
            return nil
        }
        return sqrt(x * x + y * y + z * z)
    }

    /// Accelerometer reading as tuple
    var acceleration: (x: Double, y: Double, z: Double)? {
        guard let x = accelerationX,
              let y = accelerationY,
              let z = accelerationZ else {
            return nil
        }
        return (x, y, z)
    }
}

// MARK: - Update from Diagnostics

extension BluetoothDataEntity {

    /// Update from a VehicleDiagnostics snapshot
    func update(from diagnostics: VehicleDiagnostics) {
        if let value = diagnostics.speed {
            speed = NSNumber(value: value)
        }
        if let value = diagnostics.rpm {
            rpm = NSNumber(value: value)
        }
        if let value = diagnostics.fuelLevel {
            fuel = NSNumber(value: value)
        }
        if let value = diagnostics.coolantTemp {
            coolantTemp = NSNumber(value: value)
        }
        if let value = diagnostics.engineLoad {
            engineLoad = NSNumber(value: value)
        }
        if let value = diagnostics.throttle {
            throttle = NSNumber(value: value)
        }
        if let value = diagnostics.intakeTemp {
            intakeTemp = NSNumber(value: value)
        }
        if let value = diagnostics.ambientTemp {
            ambientTemp = NSNumber(value: value)
        }
        if let value = diagnostics.barometric {
            barometric = NSNumber(value: value)
        }
        if let value = diagnostics.distance {
            distance = NSNumber(value: value)
        }
    }

    /// Update from a diagnostic reading
    func update(from reading: DiagnosticReading) {
        switch reading.pid {
        case .speed:
            speed = NSNumber(value: reading.value)
        case .rpm:
            rpm = NSNumber(value: reading.value)
        case .fuelLevel:
            fuel = NSNumber(value: reading.value)
        case .coolantTemp:
            coolantTemp = NSNumber(value: reading.value)
        case .engineLoad:
            engineLoad = NSNumber(value: reading.value)
        case .throttle:
            throttle = NSNumber(value: reading.value)
        case .intakeTemp:
            intakeTemp = NSNumber(value: reading.value)
        case .ambientTemp:
            ambientTemp = NSNumber(value: reading.value)
        case .barometric:
            barometric = NSNumber(value: reading.value)
        case .distance:
            distance = NSNumber(value: reading.value)
        default:
            break
        }
    }

    /// Update accelerometer values
    func updateAccelerometer(x: Double, y: Double, z: Double) {
        accelX = NSNumber(value: x)
        accelY = NSNumber(value: y)
        accelZ = NSNumber(value: z)
    }
}

// MARK: - Factory

extension BluetoothDataEntity {

    /// Create a new BluetoothData entity
    static func create(in context: NSManagedObjectContext) -> BluetoothDataEntity {
        return BluetoothDataEntity(context: context)
    }

    /// Create a new BluetoothData entity with initial values
    static func create(
        in context: NSManagedObjectContext,
        speed: Double? = nil,
        rpm: Double? = nil,
        fuel: Double? = nil,
        coolantTemp: Double? = nil
    ) -> BluetoothDataEntity {
        let entity = BluetoothDataEntity(context: context)
        if let value = speed { entity.speed = NSNumber(value: value) }
        if let value = rpm { entity.rpm = NSNumber(value: value) }
        if let value = fuel { entity.fuel = NSNumber(value: value) }
        if let value = coolantTemp { entity.coolantTemp = NSNumber(value: value) }
        return entity
    }
}

// MARK: - Dictionary Export

extension BluetoothDataEntity {

    /// Export all values as a dictionary (for debugging/logging)
    var dictionaryRepresentation: [String: Any] {
        var dict: [String: Any] = [:]

        if let value = speed { dict["speed"] = value }
        if let value = rpm { dict["rpm"] = value }
        if let value = fuel { dict["fuel"] = value }
        if let value = coolantTemp { dict["coolantTemp"] = value }
        if let value = engineLoad { dict["engineLoad"] = value }
        if let value = throttle { dict["throttle"] = value }
        if let value = intakeTemp { dict["intakeTemp"] = value }
        if let value = ambientTemp { dict["ambientTemp"] = value }
        if let value = barometric { dict["barometric"] = value }
        if let value = distance { dict["distance"] = value }
        if let value = accelX { dict["accelX"] = value }
        if let value = accelY { dict["accelY"] = value }
        if let value = accelZ { dict["accelZ"] = value }

        return dict
    }
}
