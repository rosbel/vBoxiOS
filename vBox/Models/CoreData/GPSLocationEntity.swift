//
//  GPSLocationEntity.swift
//  vBox
//
//  Swift Core Data model for GPSLocation entity
//

import Foundation
import CoreData
import CoreLocation

// MARK: - GPS Location Entity

@objc(GPSLocationEntity)
public class GPSLocationEntity: NSManagedObject {

    // MARK: - Core Data Properties

    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var speed: NSNumber?
    @NSManaged public var altitude: NSNumber?
    @NSManaged public var metersFromStart: NSNumber?
    @NSManaged public var timestamp: Date?
    @NSManaged public var tripInfo: TripEntity?
    @NSManaged public var bluetoothInfo: BluetoothDataEntity?
}

// MARK: - Fetch Request

extension GPSLocationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GPSLocationEntity> {
        return NSFetchRequest<GPSLocationEntity>(entityName: "GPSLocation")
    }

    /// Fetch locations for a specific trip
    @nonobjc public class func fetchLocations(for trip: TripEntity) -> NSFetchRequest<GPSLocationEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "tripInfo == %@", trip)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }

    /// Fetch locations within a time range
    @nonobjc public class func fetchLocations(from startDate: Date, to endDate: Date) -> NSFetchRequest<GPSLocationEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
}

// MARK: - Computed Properties

extension GPSLocationEntity {

    /// Coordinate as CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude?.doubleValue,
              let lon = longitude?.doubleValue else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Location as CLLocation
    var clLocation: CLLocation? {
        guard let lat = latitude?.doubleValue,
              let lon = longitude?.doubleValue else {
            return nil
        }

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: altitude?.doubleValue ?? 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: -1,
            speed: speed?.doubleValue ?? 0,
            timestamp: timestamp ?? Date()
        )
    }

    /// Speed in meters per second
    var speedMetersPerSecond: Double {
        return speed?.doubleValue ?? 0
    }

    /// Speed in kilometers per hour
    var speedKmh: Double {
        return speedMetersPerSecond * 3.6
    }

    /// Speed in miles per hour
    var speedMph: Double {
        return speedMetersPerSecond * 2.23694
    }

    /// Altitude in meters
    var altitudeMeters: Double {
        return altitude?.doubleValue ?? 0
    }

    /// Distance from trip start in meters
    var distanceFromStart: Double {
        return metersFromStart?.doubleValue ?? 0
    }

    /// Distance from trip start in kilometers
    var distanceFromStartKm: Double {
        return distanceFromStart / 1000
    }

    /// Distance from trip start in miles
    var distanceFromStartMiles: Double {
        return distanceFromStart / 1609.34
    }

    /// Whether this location has associated Bluetooth/OBD data
    var hasBluetoothData: Bool {
        return bluetoothInfo != nil
    }
}

// MARK: - Location Factory

extension GPSLocationEntity {

    /// Create a new location from a CLLocation
    static func create(
        in context: NSManagedObjectContext,
        from location: CLLocation,
        metersFromStart: Double = 0
    ) -> GPSLocationEntity {
        let entity = GPSLocationEntity(context: context)
        entity.latitude = NSNumber(value: location.coordinate.latitude)
        entity.longitude = NSNumber(value: location.coordinate.longitude)
        entity.speed = NSNumber(value: max(0, location.speed))  // Speed can be -1 if unknown
        entity.altitude = NSNumber(value: location.altitude)
        entity.metersFromStart = NSNumber(value: metersFromStart)
        entity.timestamp = location.timestamp
        return entity
    }

    /// Create a new location with specific coordinates
    static func create(
        in context: NSManagedObjectContext,
        latitude: Double,
        longitude: Double,
        speed: Double = 0,
        altitude: Double = 0,
        metersFromStart: Double = 0,
        timestamp: Date = Date()
    ) -> GPSLocationEntity {
        let entity = GPSLocationEntity(context: context)
        entity.latitude = NSNumber(value: latitude)
        entity.longitude = NSNumber(value: longitude)
        entity.speed = NSNumber(value: speed)
        entity.altitude = NSNumber(value: altitude)
        entity.metersFromStart = NSNumber(value: metersFromStart)
        entity.timestamp = timestamp
        return entity
    }
}

// MARK: - Distance Calculations

extension GPSLocationEntity {

    /// Calculate distance to another location
    func distance(to other: GPSLocationEntity) -> Double? {
        guard let selfLocation = clLocation,
              let otherLocation = other.clLocation else {
            return nil
        }
        return selfLocation.distance(from: otherLocation)
    }

    /// Calculate bearing to another location (in degrees)
    func bearing(to other: GPSLocationEntity) -> Double? {
        guard let coord1 = coordinate,
              let coord2 = other.coordinate else {
            return nil
        }

        let lat1 = coord1.latitude.degreesToRadians
        let lat2 = coord2.latitude.degreesToRadians
        let dLon = (coord2.longitude - coord1.longitude).degreesToRadians

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let bearing = atan2(y, x).radiansToDegrees

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - Helper Extensions

private extension Double {
    var degreesToRadians: Double {
        return self * .pi / 180
    }

    var radiansToDegrees: Double {
        return self * 180 / .pi
    }
}
