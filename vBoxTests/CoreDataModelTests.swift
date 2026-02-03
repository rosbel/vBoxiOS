//
//  CoreDataModelTests.swift
//  vBoxTests
//
//  Tests for Swift Core Data models
//

import XCTest
import CoreData
import CoreLocation
@testable import vBox

// MARK: - Core Data Test Base

class CoreDataTestCase: XCTestCase {

    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        testContext = createInMemoryContext()
    }

    override func tearDown() {
        testContext = nil
        super.tearDown()
    }

    /// Create an in-memory Core Data context for testing
    func createInMemoryContext() -> NSManagedObjectContext {
        // Create managed object model
        let model = NSManagedObjectModel()

        // DrivingHistory entity
        let drivingHistoryEntity = NSEntityDescription()
        drivingHistoryEntity.name = "DrivingHistory"
        drivingHistoryEntity.managedObjectClassName = NSStringFromClass(DrivingHistoryEntity.self)

        // Trip entity
        let tripEntity = NSEntityDescription()
        tripEntity.name = "Trip"
        tripEntity.managedObjectClassName = NSStringFromClass(TripEntity.self)

        let tripStartTime = NSAttributeDescription()
        tripStartTime.name = "startTime"
        tripStartTime.attributeType = .dateAttributeType
        tripStartTime.isOptional = true

        let tripEndTime = NSAttributeDescription()
        tripEndTime.name = "endTime"
        tripEndTime.attributeType = .dateAttributeType
        tripEndTime.isOptional = true

        let tripAvgSpeed = NSAttributeDescription()
        tripAvgSpeed.name = "avgSpeed"
        tripAvgSpeed.attributeType = .doubleAttributeType
        tripAvgSpeed.isOptional = true

        let tripMaxSpeed = NSAttributeDescription()
        tripMaxSpeed.name = "maxSpeed"
        tripMaxSpeed.attributeType = .doubleAttributeType
        tripMaxSpeed.isOptional = true

        let tripMinSpeed = NSAttributeDescription()
        tripMinSpeed.name = "minSpeed"
        tripMinSpeed.attributeType = .doubleAttributeType
        tripMinSpeed.isOptional = true

        let tripTotalMiles = NSAttributeDescription()
        tripTotalMiles.name = "totalMiles"
        tripTotalMiles.attributeType = .doubleAttributeType
        tripTotalMiles.isOptional = true

        let tripName = NSAttributeDescription()
        tripName.name = "tripName"
        tripName.attributeType = .stringAttributeType
        tripName.isOptional = true

        tripEntity.properties = [tripStartTime, tripEndTime, tripAvgSpeed, tripMaxSpeed, tripMinSpeed, tripTotalMiles, tripName]

        // GPSLocation entity
        let gpsLocationEntity = NSEntityDescription()
        gpsLocationEntity.name = "GPSLocation"
        gpsLocationEntity.managedObjectClassName = NSStringFromClass(GPSLocationEntity.self)

        let gpsLatitude = NSAttributeDescription()
        gpsLatitude.name = "latitude"
        gpsLatitude.attributeType = .doubleAttributeType
        gpsLatitude.isOptional = true

        let gpsLongitude = NSAttributeDescription()
        gpsLongitude.name = "longitude"
        gpsLongitude.attributeType = .doubleAttributeType
        gpsLongitude.isOptional = true

        let gpsSpeed = NSAttributeDescription()
        gpsSpeed.name = "speed"
        gpsSpeed.attributeType = .doubleAttributeType
        gpsSpeed.isOptional = true

        let gpsAltitude = NSAttributeDescription()
        gpsAltitude.name = "altitude"
        gpsAltitude.attributeType = .doubleAttributeType
        gpsAltitude.isOptional = true

        let gpsMetersFromStart = NSAttributeDescription()
        gpsMetersFromStart.name = "metersFromStart"
        gpsMetersFromStart.attributeType = .doubleAttributeType
        gpsMetersFromStart.isOptional = true

        let gpsTimestamp = NSAttributeDescription()
        gpsTimestamp.name = "timestamp"
        gpsTimestamp.attributeType = .dateAttributeType
        gpsTimestamp.isOptional = true

        gpsLocationEntity.properties = [gpsLatitude, gpsLongitude, gpsSpeed, gpsAltitude, gpsMetersFromStart, gpsTimestamp]

        // BluetoothData entity
        let bluetoothDataEntity = NSEntityDescription()
        bluetoothDataEntity.name = "BluetoothData"
        bluetoothDataEntity.managedObjectClassName = NSStringFromClass(BluetoothDataEntity.self)

        let btSpeed = NSAttributeDescription()
        btSpeed.name = "speed"
        btSpeed.attributeType = .doubleAttributeType
        btSpeed.isOptional = true

        let btRpm = NSAttributeDescription()
        btRpm.name = "rpm"
        btRpm.attributeType = .doubleAttributeType
        btRpm.isOptional = true

        let btFuel = NSAttributeDescription()
        btFuel.name = "fuel"
        btFuel.attributeType = .doubleAttributeType
        btFuel.isOptional = true

        let btCoolantTemp = NSAttributeDescription()
        btCoolantTemp.name = "coolantTemp"
        btCoolantTemp.attributeType = .doubleAttributeType
        btCoolantTemp.isOptional = true

        let btEngineLoad = NSAttributeDescription()
        btEngineLoad.name = "engineLoad"
        btEngineLoad.attributeType = .doubleAttributeType
        btEngineLoad.isOptional = true

        let btThrottle = NSAttributeDescription()
        btThrottle.name = "throttle"
        btThrottle.attributeType = .doubleAttributeType
        btThrottle.isOptional = true

        let btIntakeTemp = NSAttributeDescription()
        btIntakeTemp.name = "intakeTemp"
        btIntakeTemp.attributeType = .doubleAttributeType
        btIntakeTemp.isOptional = true

        let btAmbientTemp = NSAttributeDescription()
        btAmbientTemp.name = "ambientTemp"
        btAmbientTemp.attributeType = .doubleAttributeType
        btAmbientTemp.isOptional = true

        let btBarometric = NSAttributeDescription()
        btBarometric.name = "barometric"
        btBarometric.attributeType = .doubleAttributeType
        btBarometric.isOptional = true

        let btDistance = NSAttributeDescription()
        btDistance.name = "distance"
        btDistance.attributeType = .doubleAttributeType
        btDistance.isOptional = true

        let btAccelX = NSAttributeDescription()
        btAccelX.name = "accelX"
        btAccelX.attributeType = .doubleAttributeType
        btAccelX.isOptional = true

        let btAccelY = NSAttributeDescription()
        btAccelY.name = "accelY"
        btAccelY.attributeType = .doubleAttributeType
        btAccelY.isOptional = true

        let btAccelZ = NSAttributeDescription()
        btAccelZ.name = "accelZ"
        btAccelZ.attributeType = .doubleAttributeType
        btAccelZ.isOptional = true

        bluetoothDataEntity.properties = [btSpeed, btRpm, btFuel, btCoolantTemp, btEngineLoad, btThrottle, btIntakeTemp, btAmbientTemp, btBarometric, btDistance, btAccelX, btAccelY, btAccelZ]

        model.entities = [drivingHistoryEntity, tripEntity, gpsLocationEntity, bluetoothDataEntity]

        // Create persistent store coordinator
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: nil,
            options: nil
        )

        // Create context
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }
}

// MARK: - Trip Entity Tests

final class TripEntityTests: CoreDataTestCase {

    // MARK: - Creation Tests

    func testCreateTrip() {
        let trip = TripEntity(context: testContext)
        trip.startTime = Date()

        XCTAssertNotNil(trip)
        XCTAssertNotNil(trip.startTime)
    }

    func testTripFactoryMethod() {
        let trip = TripEntity.create(in: testContext)

        XCTAssertNotNil(trip)
        XCTAssertNotNil(trip.startTime)
    }

    func testTripFactoryWithDates() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 3600)

        let trip = TripEntity.create(in: testContext, startTime: start, endTime: end, name: "Test Trip")

        XCTAssertEqual(trip.startTime, start)
        XCTAssertEqual(trip.endTime, end)
        XCTAssertEqual(trip.tripName, "Test Trip")
    }

    // MARK: - Duration Tests

    func testDurationCalculation() {
        let trip = TripEntity(context: testContext)
        trip.startTime = Date(timeIntervalSince1970: 0)
        trip.endTime = Date(timeIntervalSince1970: 3723)

        XCTAssertEqual(trip.duration, 3723)
    }

    func testDurationStringFormatting() {
        let trip = TripEntity(context: testContext)
        trip.startTime = Date(timeIntervalSince1970: 0)
        trip.endTime = Date(timeIntervalSince1970: 3723)

        XCTAssertEqual(trip.durationString, "01:02:03")
    }

    func testDurationNilWhenMissingTimes() {
        let trip = TripEntity(context: testContext)
        XCTAssertNil(trip.duration)
    }

    // MARK: - Speed Tests

    func testSpeedProperties() {
        let trip = TripEntity(context: testContext)
        trip.avgSpeed = 65.0
        trip.maxSpeed = 85.0
        trip.minSpeed = 35.0

        XCTAssertEqual(trip.averageSpeed, 65.0)
        XCTAssertEqual(trip.maximumSpeed, 85.0)
        XCTAssertEqual(trip.minimumSpeed, 35.0)
    }

    func testSpeedDefaultsToZero() {
        let trip = TripEntity(context: testContext)

        XCTAssertEqual(trip.averageSpeed, 0)
        XCTAssertEqual(trip.maximumSpeed, 0)
        XCTAssertEqual(trip.minimumSpeed, 0)
    }

    // MARK: - Distance Tests

    func testDistanceProperties() {
        let trip = TripEntity(context: testContext)
        trip.totalMiles = 50.0

        XCTAssertEqual(trip.distanceMiles, 50.0)
        XCTAssertEqual(trip.distanceKilometers, 50.0 * 1.60934, accuracy: 0.01)
    }

    // MARK: - Location Count Tests

    func testLocationCountEmpty() {
        let trip = TripEntity(context: testContext)
        XCTAssertEqual(trip.locationCount, 0)
    }
}

// MARK: - GPS Location Entity Tests

final class GPSLocationEntityTests: CoreDataTestCase {

    // MARK: - Creation Tests

    func testCreateGPSLocation() {
        let location = GPSLocationEntity(context: testContext)
        location.latitude = 37.7749
        location.longitude = -122.4194

        XCTAssertEqual(location.latitude?.doubleValue, 37.7749)
        XCTAssertEqual(location.longitude?.doubleValue, -122.4194)
    }

    func testCreateFromCLLocation() {
        let clLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 100,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 90,
            speed: 20,
            timestamp: Date()
        )

        let location = GPSLocationEntity.create(in: testContext, from: clLocation, metersFromStart: 500)

        XCTAssertEqual(location.latitude?.doubleValue, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(location.longitude?.doubleValue, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(location.speed?.doubleValue, 20)
        XCTAssertEqual(location.altitude?.doubleValue, 100)
        XCTAssertEqual(location.metersFromStart?.doubleValue, 500)
    }

    func testCreateWithCoordinates() {
        let location = GPSLocationEntity.create(
            in: testContext,
            latitude: 34.0522,
            longitude: -118.2437,
            speed: 30,
            altitude: 50,
            metersFromStart: 1000
        )

        XCTAssertEqual(location.latitude?.doubleValue, 34.0522)
        XCTAssertEqual(location.longitude?.doubleValue, -118.2437)
        XCTAssertEqual(location.speed?.doubleValue, 30)
    }

    // MARK: - Coordinate Tests

    func testCoordinateProperty() {
        let location = GPSLocationEntity(context: testContext)
        location.latitude = 37.7749
        location.longitude = -122.4194

        let coordinate = location.coordinate

        XCTAssertNotNil(coordinate)
        XCTAssertEqual(coordinate?.latitude, 37.7749)
        XCTAssertEqual(coordinate?.longitude, -122.4194)
    }

    func testCoordinateNilWhenMissing() {
        let location = GPSLocationEntity(context: testContext)
        XCTAssertNil(location.coordinate)
    }

    // MARK: - Speed Conversion Tests

    func testSpeedConversions() {
        let location = GPSLocationEntity(context: testContext)
        location.speed = 20.0  // 20 m/s

        XCTAssertEqual(location.speedMetersPerSecond, 20.0)
        XCTAssertEqual(location.speedKmh, 72.0, accuracy: 0.1)  // 20 * 3.6
        XCTAssertEqual(location.speedMph, 44.7, accuracy: 0.1)  // 20 * 2.23694
    }

    // MARK: - Distance Conversion Tests

    func testDistanceConversions() {
        let location = GPSLocationEntity(context: testContext)
        location.metersFromStart = 10000.0  // 10 km

        XCTAssertEqual(location.distanceFromStart, 10000.0)
        XCTAssertEqual(location.distanceFromStartKm, 10.0)
        XCTAssertEqual(location.distanceFromStartMiles, 6.21, accuracy: 0.01)
    }

    // MARK: - CLLocation Conversion Tests

    func testCLLocationConversion() {
        let location = GPSLocationEntity(context: testContext)
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.altitude = 100
        location.speed = 20
        location.timestamp = Date()

        let clLocation = location.clLocation

        XCTAssertNotNil(clLocation)
        XCTAssertEqual(clLocation?.coordinate.latitude, 37.7749)
        XCTAssertEqual(clLocation?.coordinate.longitude, -122.4194)
    }

    // MARK: - Bluetooth Data Association Tests

    func testHasBluetoothDataFalseWhenNil() {
        let location = GPSLocationEntity(context: testContext)
        XCTAssertFalse(location.hasBluetoothData)
    }
}

// MARK: - Bluetooth Data Entity Tests

final class BluetoothDataEntityTests: CoreDataTestCase {

    // MARK: - Creation Tests

    func testCreateBluetoothData() {
        let data = BluetoothDataEntity(context: testContext)
        data.speed = 65.0
        data.rpm = 3000.0
        data.fuel = 75.0

        XCTAssertEqual(data.speed?.doubleValue, 65.0)
        XCTAssertEqual(data.rpm?.doubleValue, 3000.0)
        XCTAssertEqual(data.fuel?.doubleValue, 75.0)
    }

    func testFactoryMethod() {
        let data = BluetoothDataEntity.create(
            in: testContext,
            speed: 60,
            rpm: 2500,
            fuel: 80,
            coolantTemp: 90
        )

        XCTAssertEqual(data.speedKmh, 60)
        XCTAssertEqual(data.engineRpm, 2500)
        XCTAssertEqual(data.fuelLevel, 80)
        XCTAssertEqual(data.coolantTemperature, 90)
    }

    // MARK: - Speed Tests

    func testSpeedConversions() {
        let data = BluetoothDataEntity(context: testContext)
        data.speed = 100.0  // 100 km/h

        XCTAssertEqual(data.speedKmh, 100.0)
        XCTAssertEqual(data.speedMph!, 62.14, accuracy: 0.01)
    }

    // MARK: - Fuel Tests

    func testFuelLevel() {
        let data = BluetoothDataEntity(context: testContext)
        data.fuel = 75.0

        XCTAssertEqual(data.fuelLevel, 75.0)
        XCTAssertFalse(data.isFuelLow)
    }

    func testFuelLowWarning() {
        let data = BluetoothDataEntity(context: testContext)
        data.fuel = 10.0

        XCTAssertTrue(data.isFuelLow)
    }

    func testFuelLowThreshold() {
        let data = BluetoothDataEntity(context: testContext)

        data.fuel = 14.9
        XCTAssertTrue(data.isFuelLow)

        data.fuel = 15.0
        XCTAssertFalse(data.isFuelLow)
    }

    // MARK: - Temperature Tests

    func testCoolantTemperature() {
        let data = BluetoothDataEntity(context: testContext)
        data.coolantTemp = 90.0

        XCTAssertEqual(data.coolantTemperature, 90.0)
        XCTAssertEqual(data.coolantTemperatureFahrenheit!, 194.0, accuracy: 0.1)
    }

    func testOperatingTemperature() {
        let data = BluetoothDataEntity(context: testContext)

        data.coolantTemp = 70.0
        XCTAssertFalse(data.isAtOperatingTemperature)

        data.coolantTemp = 90.0
        XCTAssertTrue(data.isAtOperatingTemperature)

        data.coolantTemp = 110.0
        XCTAssertFalse(data.isAtOperatingTemperature)
    }

    func testOverheating() {
        let data = BluetoothDataEntity(context: testContext)

        data.coolantTemp = 100.0
        XCTAssertFalse(data.isOverheating)

        data.coolantTemp = 106.0
        XCTAssertTrue(data.isOverheating)
    }

    // MARK: - Accelerometer Tests

    func testAccelerometerValues() {
        let data = BluetoothDataEntity(context: testContext)
        data.accelX = 0.1
        data.accelY = 0.2
        data.accelZ = 0.3

        XCTAssertEqual(data.accelerationX, 0.1)
        XCTAssertEqual(data.accelerationY, 0.2)
        XCTAssertEqual(data.accelerationZ, 0.3)
    }

    func testAccelerometerMagnitude() {
        let data = BluetoothDataEntity(context: testContext)
        data.accelX = 3.0
        data.accelY = 4.0
        data.accelZ = 0.0

        XCTAssertEqual(data.accelerationMagnitude!, 5.0, accuracy: 0.001)
    }

    func testAccelerometerTuple() {
        let data = BluetoothDataEntity(context: testContext)
        data.accelX = 1.0
        data.accelY = 2.0
        data.accelZ = 3.0

        let accel = data.acceleration

        XCTAssertNotNil(accel)
        XCTAssertEqual(accel?.x, 1.0)
        XCTAssertEqual(accel?.y, 2.0)
        XCTAssertEqual(accel?.z, 3.0)
    }

    // MARK: - Update Methods Tests

    func testUpdateFromDiagnostics() {
        let data = BluetoothDataEntity(context: testContext)

        var diagnostics = VehicleDiagnostics()
        diagnostics.update(with: DiagnosticReading(pid: .speed, value: 65.0))
        diagnostics.update(with: DiagnosticReading(pid: .rpm, value: 3000.0))
        diagnostics.update(with: DiagnosticReading(pid: .fuelLevel, value: 75.0))

        data.update(from: diagnostics)

        XCTAssertEqual(data.speedKmh, 65.0)
        XCTAssertEqual(data.engineRpm, 3000.0)
        XCTAssertEqual(data.fuelLevel, 75.0)
    }

    func testUpdateFromDiagnosticReading() {
        let data = BluetoothDataEntity(context: testContext)

        data.update(from: DiagnosticReading(pid: .throttle, value: 30.0))

        XCTAssertEqual(data.throttlePosition, 30.0)
    }

    func testUpdateAccelerometer() {
        let data = BluetoothDataEntity(context: testContext)

        data.updateAccelerometer(x: 0.5, y: -0.3, z: 9.8)

        XCTAssertEqual(data.accelerationX, 0.5)
        XCTAssertEqual(data.accelerationY, -0.3)
        XCTAssertEqual(data.accelerationZ, 9.8)
    }

    // MARK: - Dictionary Export Tests

    func testDictionaryRepresentation() {
        let data = BluetoothDataEntity(context: testContext)
        data.speed = 65.0
        data.rpm = 3000.0

        let dict = data.dictionaryRepresentation

        XCTAssertEqual(dict["speed"] as? NSNumber, 65.0)
        XCTAssertEqual(dict["rpm"] as? NSNumber, 3000.0)
        XCTAssertNil(dict["fuel"])  // Not set, shouldn't be in dict
    }
}

// MARK: - Driving History Entity Tests

final class DrivingHistoryEntityTests: CoreDataTestCase {

    // MARK: - Creation Tests

    func testCreateDrivingHistory() {
        let history = DrivingHistoryEntity(context: testContext)
        XCTAssertNotNil(history)
        XCTAssertEqual(history.tripCount, 0)
    }

    func testGetOrCreate() {
        let history1 = DrivingHistoryEntity.getOrCreate(in: testContext)
        try! testContext.save()

        let history2 = DrivingHistoryEntity.getOrCreate(in: testContext)

        XCTAssertEqual(history1, history2)
    }

    // MARK: - Trip Management Tests

    func testTripCount() {
        let history = DrivingHistoryEntity(context: testContext)

        XCTAssertEqual(history.tripCount, 0)
    }

    func testTripsArrayEmpty() {
        let history = DrivingHistoryEntity(context: testContext)

        XCTAssertEqual(history.tripsArray.count, 0)
    }

    // MARK: - Statistics Tests

    func testStatisticsEmpty() {
        let history = DrivingHistoryEntity(context: testContext)
        let stats = history.statistics

        XCTAssertEqual(stats.totalTrips, 0)
        XCTAssertEqual(stats.totalDistanceMiles, 0)
        XCTAssertEqual(stats.totalDrivingTime, 0)
    }
}

// MARK: - Driving Statistics Tests

final class DrivingStatisticsTests: XCTestCase {

    func testDistanceConversion() {
        let stats = DrivingStatistics(
            totalTrips: 10,
            totalDistanceMiles: 100,
            totalDrivingTime: 3600,
            averageTripDistanceMiles: 10,
            averageTripDuration: 360,
            maxSpeedRecorded: 85,
            averageSpeed: 45
        )

        XCTAssertEqual(stats.totalDistanceKilometers, 160.934, accuracy: 0.01)
    }

    func testFormattedTotalTime() {
        let stats = DrivingStatistics(
            totalTrips: 5,
            totalDistanceMiles: 50,
            totalDrivingTime: 7200,  // 2 hours
            averageTripDistanceMiles: 10,
            averageTripDuration: 1440,
            maxSpeedRecorded: 75,
            averageSpeed: 40
        )

        XCTAssertEqual(stats.formattedTotalTime, "2 hours")
    }
}
