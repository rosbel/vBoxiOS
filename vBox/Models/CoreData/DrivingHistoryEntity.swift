//
//  DrivingHistoryEntity.swift
//  vBox
//
//  Swift Core Data model for DrivingHistory entity
//

import Foundation
import CoreData

// MARK: - Driving History Entity

@objc(DrivingHistoryEntity)
public class DrivingHistoryEntity: NSManagedObject {

    // MARK: - Core Data Properties

    @NSManaged public var trips: NSOrderedSet?
}

// MARK: - Fetch Request

extension DrivingHistoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrivingHistoryEntity> {
        return NSFetchRequest<DrivingHistoryEntity>(entityName: "DrivingHistory")
    }
}

// MARK: - Generated Accessors for trips

extension DrivingHistoryEntity {

    @objc(insertObject:inTripsAtIndex:)
    @NSManaged public func insertIntoTrips(_ value: TripEntity, at idx: Int)

    @objc(removeObjectFromTripsAtIndex:)
    @NSManaged public func removeFromTrips(at idx: Int)

    @objc(insertTrips:atIndexes:)
    @NSManaged public func insertIntoTrips(_ values: [TripEntity], at indexes: NSIndexSet)

    @objc(removeTripsAtIndexes:)
    @NSManaged public func removeFromTrips(at indexes: NSIndexSet)

    @objc(replaceObjectInTripsAtIndex:withObject:)
    @NSManaged public func replaceTrips(at idx: Int, with value: TripEntity)

    @objc(replaceTripsAtIndexes:withTrips:)
    @NSManaged public func replaceTrips(at indexes: NSIndexSet, with values: [TripEntity])

    @objc(addTripsObject:)
    @NSManaged public func addToTrips(_ value: TripEntity)

    @objc(removeTripsObject:)
    @NSManaged public func removeFromTrips(_ value: TripEntity)

    @objc(addTrips:)
    @NSManaged public func addToTrips(_ values: NSOrderedSet)

    @objc(removeTrips:)
    @NSManaged public func removeFromTrips(_ values: NSOrderedSet)
}

// MARK: - Computed Properties

extension DrivingHistoryEntity {

    /// Number of trips
    var tripCount: Int {
        return trips?.count ?? 0
    }

    /// Array of all trips
    var tripsArray: [TripEntity] {
        return trips?.array as? [TripEntity] ?? []
    }

    /// Trips sorted by start time (newest first)
    var tripsSortedByDate: [TripEntity] {
        return tripsArray.sorted { (trip1, trip2) -> Bool in
            guard let date1 = trip1.startTime, let date2 = trip2.startTime else {
                return false
            }
            return date1 > date2
        }
    }

    /// Most recent trip
    var mostRecentTrip: TripEntity? {
        return tripsSortedByDate.first
    }

    /// Oldest trip
    var oldestTrip: TripEntity? {
        return tripsSortedByDate.last
    }

    /// Total distance of all trips in miles
    var totalDistanceMiles: Double {
        return tripsArray.reduce(0) { $0 + $1.distanceMiles }
    }

    /// Total distance of all trips in kilometers
    var totalDistanceKilometers: Double {
        return totalDistanceMiles * 1.60934
    }

    /// Total driving time across all trips
    var totalDrivingTime: TimeInterval {
        return tripsArray.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    /// Formatted total driving time
    var totalDrivingTimeString: String {
        return DurationFormatter.string(from: totalDrivingTime)
    }

    /// Average trip distance in miles
    var averageTripDistanceMiles: Double {
        guard tripCount > 0 else { return 0 }
        return totalDistanceMiles / Double(tripCount)
    }

    /// Average trip duration
    var averageTripDuration: TimeInterval {
        guard tripCount > 0 else { return 0 }
        return totalDrivingTime / Double(tripCount)
    }
}

// MARK: - Trip Management

extension DrivingHistoryEntity {

    /// Create and add a new trip
    func createTrip(in context: NSManagedObjectContext) -> TripEntity {
        let trip = TripEntity.create(in: context)
        trip.drivingHistory = self
        addToTrips(trip)
        return trip
    }

    /// Remove a trip
    func removeTrip(_ trip: TripEntity, from context: NSManagedObjectContext) {
        removeFromTrips(trip)
        context.delete(trip)
    }

    /// Get trips for a specific date
    func trips(on date: Date) -> [TripEntity] {
        let calendar = Calendar.current
        return tripsArray.filter { trip in
            guard let tripDate = trip.startTime else { return false }
            return calendar.isDate(tripDate, inSameDayAs: date)
        }
    }

    /// Get trips within a date range
    func trips(from startDate: Date, to endDate: Date) -> [TripEntity] {
        return tripsArray.filter { trip in
            guard let tripDate = trip.startTime else { return false }
            return tripDate >= startDate && tripDate <= endDate
        }
    }

    /// Get trips grouped by date (for table view sections)
    var tripsGroupedByDate: [(date: Date, trips: [TripEntity])] {
        let calendar = Calendar.current

        // Group trips by day
        var grouped: [Date: [TripEntity]] = [:]

        for trip in tripsArray {
            guard let startTime = trip.startTime else { continue }

            let dayStart = calendar.startOfDay(for: startTime)

            if grouped[dayStart] == nil {
                grouped[dayStart] = []
            }
            grouped[dayStart]?.append(trip)
        }

        // Convert to sorted array of tuples
        return grouped
            .map { (date: $0.key, trips: $0.value.sorted { ($0.startTime ?? Date()) > ($1.startTime ?? Date()) }) }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - Statistics

extension DrivingHistoryEntity {

    /// Overall statistics summary
    var statistics: DrivingStatistics {
        return DrivingStatistics(
            totalTrips: tripCount,
            totalDistanceMiles: totalDistanceMiles,
            totalDrivingTime: totalDrivingTime,
            averageTripDistanceMiles: averageTripDistanceMiles,
            averageTripDuration: averageTripDuration,
            maxSpeedRecorded: tripsArray.map { $0.maximumSpeed }.max() ?? 0,
            averageSpeed: tripsArray.isEmpty ? 0 : tripsArray.map { $0.averageSpeed }.reduce(0, +) / Double(tripCount)
        )
    }
}

// MARK: - Driving Statistics

/// Summary of driving statistics
struct DrivingStatistics {
    let totalTrips: Int
    let totalDistanceMiles: Double
    let totalDrivingTime: TimeInterval
    let averageTripDistanceMiles: Double
    let averageTripDuration: TimeInterval
    let maxSpeedRecorded: Double
    let averageSpeed: Double

    var totalDistanceKilometers: Double {
        return totalDistanceMiles * 1.60934
    }

    var formattedTotalTime: String {
        return DurationFormatter.humanReadable(from: totalDrivingTime)
    }

    var formattedAverageDuration: String {
        return DurationFormatter.humanReadable(from: averageTripDuration)
    }
}

// MARK: - Singleton Access

extension DrivingHistoryEntity {

    /// Get or create the singleton DrivingHistory instance
    static func getOrCreate(in context: NSManagedObjectContext) -> DrivingHistoryEntity {
        let request = fetchRequest()
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let history = DrivingHistoryEntity(context: context)
        return history
    }
}
