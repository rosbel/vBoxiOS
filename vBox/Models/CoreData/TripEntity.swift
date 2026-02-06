//
//  TripEntity.swift
//  vBox
//
//  Swift Core Data model for Trip entity
//

import Foundation
import CoreData
import CoreLocation

// MARK: - Trip Entity

@objc(TripEntity)
public class TripEntity: NSManagedObject {

    // MARK: - Core Data Properties

    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var avgSpeed: NSNumber?
    @NSManaged public var maxSpeed: NSNumber?
    @NSManaged public var minSpeed: NSNumber?
    @NSManaged public var totalMiles: NSNumber?
    @NSManaged public var tripName: String?
    @NSManaged public var drivingHistory: DrivingHistoryEntity?
    @NSManaged public var gpsLocations: NSOrderedSet?
}

// MARK: - Fetch Request

extension TripEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TripEntity> {
        return NSFetchRequest<TripEntity>(entityName: "Trip")
    }

    /// Fetch all trips sorted by start time (newest first)
    @nonobjc public class func fetchAllSortedByDate() -> NSFetchRequest<TripEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        return request
    }

    /// Fetch trips within a date range
    @nonobjc public class func fetchTrips(from startDate: Date, to endDate: Date) -> NSFetchRequest<TripEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        return request
    }
}

// MARK: - Generated Accessors for gpsLocations

extension TripEntity {

    @objc(insertObject:inGpsLocationsAtIndex:)
    @NSManaged public func insertIntoGpsLocations(_ value: GPSLocationEntity, at idx: Int)

    @objc(removeObjectFromGpsLocationsAtIndex:)
    @NSManaged public func removeFromGpsLocations(at idx: Int)

    @objc(insertGpsLocations:atIndexes:)
    @NSManaged public func insertIntoGpsLocations(_ values: [GPSLocationEntity], at indexes: NSIndexSet)

    @objc(removeGpsLocationsAtIndexes:)
    @NSManaged public func removeFromGpsLocations(at indexes: NSIndexSet)

    @objc(replaceObjectInGpsLocationsAtIndex:withObject:)
    @NSManaged public func replaceGpsLocations(at idx: Int, with value: GPSLocationEntity)

    @objc(replaceGpsLocationsAtIndexes:withGpsLocations:)
    @NSManaged public func replaceGpsLocations(at indexes: NSIndexSet, with values: [GPSLocationEntity])

    @objc(addGpsLocationsObject:)
    @NSManaged public func addToGpsLocations(_ value: GPSLocationEntity)

    @objc(removeGpsLocationsObject:)
    @NSManaged public func removeFromGpsLocations(_ value: GPSLocationEntity)

    @objc(addGpsLocations:)
    @NSManaged public func addToGpsLocations(_ values: NSOrderedSet)

    @objc(removeGpsLocations:)
    @NSManaged public func removeFromGpsLocations(_ values: NSOrderedSet)
}

// MARK: - Computed Properties

extension TripEntity {

    /// Duration of the trip in seconds
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }

    /// Formatted duration string (HH:MM:SS)
    var durationString: String {
        guard let duration = duration else { return "00:00:00" }
        return DurationFormatter.string(from: duration)
    }

    /// Human-readable duration
    var humanReadableDuration: String {
        guard let duration = duration else { return "Unknown" }
        return DurationFormatter.humanReadable(from: duration)
    }

    /// Average speed as Double
    var averageSpeed: Double {
        return avgSpeed?.doubleValue ?? 0
    }

    /// Maximum speed as Double
    var maximumSpeed: Double {
        return maxSpeed?.doubleValue ?? 0
    }

    /// Minimum speed as Double
    var minimumSpeed: Double {
        return minSpeed?.doubleValue ?? 0
    }

    /// Total distance in miles as Double
    var distanceMiles: Double {
        return totalMiles?.doubleValue ?? 0
    }

    /// Total distance in kilometers
    var distanceKilometers: Double {
        return distanceMiles * 1.60934
    }

    /// Number of GPS locations recorded
    var locationCount: Int {
        return gpsLocations?.count ?? 0
    }

    /// Array of GPS locations
    var locationsArray: [GPSLocationEntity] {
        return gpsLocations?.array as? [GPSLocationEntity] ?? []
    }

    /// First GPS location (trip start point)
    var startLocation: GPSLocationEntity? {
        return gpsLocations?.firstObject as? GPSLocationEntity
    }

    /// Last GPS location (trip end point)
    var endLocation: GPSLocationEntity? {
        return gpsLocations?.lastObject as? GPSLocationEntity
    }

    /// Start coordinate
    var startCoordinate: CLLocationCoordinate2D? {
        guard let location = startLocation,
              let lat = location.latitude?.doubleValue,
              let lon = location.longitude?.doubleValue else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// End coordinate
    var endCoordinate: CLLocationCoordinate2D? {
        guard let location = endLocation,
              let lat = location.latitude?.doubleValue,
              let lon = location.longitude?.doubleValue else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Path as array of coordinates
    var pathCoordinates: [CLLocationCoordinate2D] {
        return locationsArray.compactMap { location in
            guard let lat = location.latitude?.doubleValue,
                  let lon = location.longitude?.doubleValue else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

// MARK: - Trip Statistics

extension TripEntity {

    /// Calculate and update trip statistics from recorded locations
    func calculateStatistics() {
        let locations = locationsArray

        guard !locations.isEmpty else { return }

        // Calculate speeds
        let speeds = locations.compactMap { $0.speed?.doubleValue }

        if !speeds.isEmpty {
            avgSpeed = NSNumber(value: speeds.reduce(0, +) / Double(speeds.count))
            maxSpeed = NSNumber(value: speeds.max() ?? 0)
            minSpeed = NSNumber(value: speeds.min() ?? 0)
        }

        // Calculate total distance
        if let lastLocation = locations.last,
           let distance = lastLocation.metersFromStart?.doubleValue {
            // Convert meters to miles
            totalMiles = NSNumber(value: distance / 1609.34)
        }
    }
}

// MARK: - Trip Factory

extension TripEntity {

    /// Create a new trip in the given context
    static func create(in context: NSManagedObjectContext) -> TripEntity {
        let trip = TripEntity(context: context)
        trip.startTime = Date()
        return trip
    }

    /// Create a trip with specific start/end times (for testing)
    static func create(
        in context: NSManagedObjectContext,
        startTime: Date,
        endTime: Date,
        name: String? = nil
    ) -> TripEntity {
        let trip = TripEntity(context: context)
        trip.startTime = startTime
        trip.endTime = endTime
        trip.tripName = name
        return trip
    }
}
