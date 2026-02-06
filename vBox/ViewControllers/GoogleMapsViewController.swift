//
//  GoogleMapsViewController.swift
//  vBox
//
//  Swift implementation of main driving/recording view
//

import UIKit
import CoreLocation
import GoogleMaps
import Combine

// MARK: - Delegate Protocol

@objc protocol GoogleMapsViewControllerSwiftDelegate: AnyObject {
    func didTapStopRecordingButton()
}

// MARK: - Google Maps View Controller

final class GoogleMapsViewControllerSwift: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var MapView: GMSMapView!
    @IBOutlet private weak var stopRecordingButton: UIButton!
    @IBOutlet private weak var speedOrDistanceLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var bleButton: UIButton!
    @IBOutlet private weak var bluetoothRequiredLabel: UILabel!
    @IBOutlet private weak var infoView: UIView!
    @IBOutlet private weak var mapViewToInfoViewConstraint: NSLayoutConstraint!

    // MARK: - Properties

    @objc weak var delegate: GoogleMapsViewControllerSwiftDelegate?

    private var locationManager: CLLocationManager!
    private var bleManager: BLEManagerSwift?
    private var cancellables = Set<AnyCancellable>()

    private var completePath: GMSMutablePath!
    private var polyline: GMSPolyline!
    private var prevLocation: CLLocation?
    private var isFollowingMe = true
    private var showSpeed = true
    private var isBLEOn = false

    private var currentTrip: Trip!
    private var sumSpeed: Double = 0
    private var maxSpeed: Double = 0
    private var minSpeed: Double = .greatestFiniteMagnitude

    private var infoViewFrame: CGRect = .zero
    private var mapViewFrame: CGRect = .zero
    private var infoViewHiddenOffScreen: CGRect = .zero

    private var bluetoothDiagnostics: [String: NSNumber] = [:]

    private var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    private var context: NSManagedObjectContext {
        return appDelegate.managedObjectContext
    }

    private let pathStyles: [GMSStrokeStyle] = [
        .solidColor(UIColor(red: 0.2666666667, green: 0.4666666667, blue: 0.6, alpha: 1)),
        .solidColor(UIColor(red: 0.6666666667, green: 0.8, blue: 0.8, alpha: 1))
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create new trip
        currentTrip = NSEntityDescription.insertNewObject(forEntityName: "Trip", into: context) as? Trip
        currentTrip.startTime = Date()

        completePath = GMSMutablePath()

        setupUI()
        setupLocationManager()
        setupGoogleMaps()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        infoViewFrame = infoView.frame
        mapViewFrame = MapView.frame
        infoViewHiddenOffScreen = infoView.frame
        infoViewHiddenOffScreen.origin.y = UIScreen.main.bounds.height

        updateViewsBasedOnBLEState(isBLEOn, animate: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        MapView.clear()
        locationManager.stopUpdatingLocation()

        cleanUpBluetoothManager()

        // Delete trip if no locations recorded
        if currentTrip.gpsLocations?.count == 0 {
            context.delete(currentTrip)
            appDelegate.saveContext()
            super.viewWillDisappear(animated)
            return
        }

        // Save trip statistics
        currentTrip.endTime = Date()
        let count = currentTrip.gpsLocations?.count ?? 0
        let avgSpeed = count > 0 ? sumSpeed / Double(count) : 0
        currentTrip.avgSpeed = NSNumber(value: avgSpeed)
        currentTrip.maxSpeed = NSNumber(value: maxSpeed)
        currentTrip.minSpeed = NSNumber(value: minSpeed)
        currentTrip.totalMiles = NSNumber(value: GMSGeometryLength(completePath) * 0.000621371)

        appDelegate.drivingHistory.addToTrips(currentTrip)
        appDelegate.saveContext()

        super.viewWillDisappear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    // MARK: - Setup

    private func setupUI() {
        // Speed label tap gesture
        speedOrDistanceLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(speedLabelTapped))
        speedOrDistanceLabel.addGestureRecognizer(tapGesture)

        // Button styling
        bleButton.layer.masksToBounds = true
        bleButton.layer.cornerRadius = 5.0

        stopRecordingButton.layer.masksToBounds = true
        stopRecordingButton.layer.cornerRadius = 5.0
        let buttonColor = UIColor(red: 0, green: 122.0 / 255.0, blue: 1, alpha: 1)
        stopRecordingButton.setBackgroundImage(MyStyleKit.image(ofVBoxButtonWithButtonColor: buttonColor), for: .normal)

        speedOrDistanceLabel.layer.masksToBounds = true
        speedOrDistanceLabel.layer.cornerRadius = 5.0
    }

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = true

        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func setupGoogleMaps() {
        let camera = GMSCameraPosition(latitude: 39.490179, longitude: -98.081992, zoom: 3)

        MapView.padding = UIEdgeInsets(top: 85, left: 0, bottom: 0, right: 5)
        MapView.camera = camera
        MapView.isMyLocationEnabled = true
        MapView.settings.myLocationButton = true
        MapView.settings.compassButton = true
        MapView.delegate = self

        polyline = GMSPolyline(path: completePath)
        polyline.strokeColor = .gray
        polyline.strokeWidth = 5.0
        polyline.geodesic = true
        polyline.map = MapView
    }

    private func setupBluetoothManager() {
        bleManager = BLEManagerSwift()

        // Subscribe to state changes
        bleManager?.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleBLEStateChange(state)
            }
            .store(in: &cancellables)

        // Subscribe to connection changes
        bleManager?.connectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    SVProgressHUD.showSuccess(withStatus: "Connected")
                } else {
                    SVProgressHUD.showError(withStatus: "Disconnected")
                }
            }
            .store(in: &cancellables)

        // Subscribe to diagnostics
        bleManager?.diagnosticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] diagnostics in
                self?.updateBluetoothDiagnostics(diagnostics)
            }
            .store(in: &cancellables)

        // Subscribe to scanning status
        bleManager?.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { isScanning in
                if isScanning {
                    SVProgressHUD.show(withStatus: "Scanning...")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - BLE State Handling

    private func handleBLEStateChange(_ state: BLEState) {
        switch state {
        case .on:
            bluetoothRequiredLabel.isHidden = true
            let peripheralType: PeripheralType = UserDefaults.standard.bool(forKey: "connectToOBD") ? .obdAdapter : .beagleBone
            _ = bleManager?.scan(for: peripheralType)
        case .off:
            SVProgressHUD.showError(withStatus: "Bluetooth Off")
            bluetoothRequiredLabel.isHidden = false
        case .resetting:
            SVProgressHUD.showError(withStatus: "Bluetooth Resetting")
            bluetoothRequiredLabel.isHidden = false
        case .unauthorized:
            SVProgressHUD.showError(withStatus: "Bluetooth Unauthorized")
            bluetoothRequiredLabel.isHidden = false
        case .unknown:
            SVProgressHUD.showError(withStatus: "Bluetooth State Unknown")
            bluetoothRequiredLabel.isHidden = false
        case .unsupported:
            SVProgressHUD.showError(withStatus: "Bluetooth Unsupported")
            bluetoothRequiredLabel.isHidden = false
        }
    }

    private func updateBluetoothDiagnostics(_ diagnostics: VehicleDiagnostics) {
        if let speed = diagnostics.speed {
            bluetoothDiagnostics["Speed"] = NSNumber(value: speed)
        }
        if let rpm = diagnostics.rpm {
            bluetoothDiagnostics["RPM"] = NSNumber(value: rpm)
        }
        if let fuel = diagnostics.fuelLevel {
            bluetoothDiagnostics["Fuel"] = NSNumber(value: fuel)
        }
        if let coolant = diagnostics.coolantTemp {
            bluetoothDiagnostics["Coolant Temp"] = NSNumber(value: coolant)
        }
        if let intake = diagnostics.intakeTemp {
            bluetoothDiagnostics["Intake Temp"] = NSNumber(value: intake)
        }
        if let ambient = diagnostics.ambientTemp {
            bluetoothDiagnostics["Ambient Temp"] = NSNumber(value: ambient)
        }
        if let load = diagnostics.engineLoad {
            bluetoothDiagnostics["Engine Load"] = NSNumber(value: load)
        }
        if let throttle = diagnostics.throttlePosition {
            bluetoothDiagnostics["Throttle"] = NSNumber(value: throttle)
        }
        if let barometric = diagnostics.barometricPressure {
            bluetoothDiagnostics["Barometric"] = NSNumber(value: barometric)
        }
        if let distance = diagnostics.distanceSinceCodesCleared {
            bluetoothDiagnostics["Distance"] = NSNumber(value: distance)
        }

        collectionView.reloadData()
    }

    // MARK: - Actions

    @IBAction private func stopRecordingButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        delegate?.didTapStopRecordingButton()
    }

    @IBAction private func bleButtonTapped(_ sender: UIButton) {
        isBLEOn.toggle()

        if isBLEOn {
            sender.setImage(UIImage(named: "bleOn"), for: .normal)
            setupBluetoothManager()
        } else {
            sender.setImage(UIImage(named: "bleOff"), for: .normal)
            cleanUpBluetoothManager()
        }

        updateViewsBasedOnBLEState(isBLEOn, animate: true)
    }

    @objc private func speedLabelTapped() {
        showSpeed.toggle()
        updateSpeedLabel(with: prevLocation)
    }

    // MARK: - UI Updates

    private func updateSpeedLabel(with location: CLLocation?) {
        guard let location = location else { return }

        if showSpeed {
            speedOrDistanceLabel.text = String(format: " %.2f mph", location.speed * 2.23694)
        } else {
            speedOrDistanceLabel.text = String(format: " %.2f mi", GMSGeometryLength(completePath) * 0.000621371)
        }
    }

    private func updateViewsBasedOnBLEState(_ state: Bool, animate: Bool) {
        let animations: () -> Void = {
            if state {
                self.infoView.frame = self.infoViewFrame
                self.MapView.frame = self.mapViewFrame
                self.infoView.isHidden = false
            } else {
                self.infoView.frame = self.infoViewHiddenOffScreen
                self.MapView.frame = UIScreen.main.bounds
            }
        }

        let completion: (Bool) -> Void = { _ in
            if !state {
                self.infoView.isHidden = true
            }
            self.bleButton.isEnabled = true
        }

        if animate {
            bleButton.isEnabled = false
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: animations, completion: completion)
        } else {
            animations()
            if !state {
                infoView.isHidden = true
            }
        }
    }

    // MARK: - Core Data

    private func logLocation(_ location: CLLocation, persistent: Bool) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let speedMPH = max(0, location.speed * 2.236936284)
        let altitude = location.altitude * 3.28084

        guard persistent else { return }

        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "GPSLocation", into: context) as! GPSLocation
        newLocation.latitude = NSNumber(value: lat)
        newLocation.longitude = NSNumber(value: lon)
        newLocation.speed = NSNumber(value: speedMPH)
        newLocation.metersFromStart = NSNumber(value: GMSGeometryLength(completePath))
        newLocation.timestamp = location.timestamp
        newLocation.tripInfo = currentTrip
        newLocation.altitude = NSNumber(value: altitude)

        // Add Bluetooth data if connected
        if let bleManager = bleManager, bleManager.isConnected {
            let bleData = NSEntityDescription.insertNewObject(forEntityName: "BluetoothData", into: context) as! BluetoothData

            // Convert speed from km/h to mph
            if let speedKmh = bluetoothDiagnostics["Speed"] {
                bleData.speed = NSNumber(value: speedKmh.doubleValue * 0.621371)
            }

            bleData.ambientTemp = bluetoothDiagnostics["Ambient Temp"]
            bleData.barometric = bluetoothDiagnostics["Barometric"]
            bleData.rpm = bluetoothDiagnostics["RPM"]
            bleData.intakeTemp = bluetoothDiagnostics["Intake Temp"]
            bleData.fuel = bluetoothDiagnostics["Fuel"]
            bleData.engineLoad = bluetoothDiagnostics["Engine Load"]
            bleData.distance = bluetoothDiagnostics["Distance"]
            bleData.coolantTemp = bluetoothDiagnostics["Coolant Temp"]
            bleData.throttle = bluetoothDiagnostics["Throttle"]

            newLocation.bluetoothInfo = bleData
        }

        appDelegate.saveContext()
    }

    // MARK: - Cleanup

    private func cleanUpBluetoothManager() {
        if let bleManager = bleManager {
            if bleManager.isConnected {
                bleManager.disconnect()
            }
            bleManager.stopScanning()
        }

        cancellables.removeAll()
        bleManager = nil

        SVProgressHUD.dismiss()
    }
}

// MARK: - CLLocationManagerDelegate

extension GoogleMapsViewControllerSwift: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newestLocation = locations.last else { return }

        // Initial camera positioning
        if isFollowingMe && prevLocation == nil && newestLocation.horizontalAccuracy < 70 {
            MapView.animate(toLocation: newestLocation.coordinate)
            if MapView.camera.zoom < 10 {
                MapView.animate(toZoom: 15)
            }
        }

        for location in locations {
            // Skip inaccurate readings
            guard location.horizontalAccuracy <= 30 else { continue }

            let speedMPH = max(0, newestLocation.speed * 2.236936284)

            // Update statistics
            if speedMPH < minSpeed {
                minSpeed = speedMPH
            }
            if speedMPH > maxSpeed {
                maxSpeed = speedMPH
            }
            sumSpeed += speedMPH

            updateSpeedLabel(with: newestLocation)
            logLocation(newestLocation, persistent: true)

            completePath.add(newestLocation.coordinate)
            polyline.path = completePath
        }

        // Update polyline styling
        let tolerance = pow(10.0, (-0.301 * Double(MapView.camera.zoom)) + 9.0731) / 2500.0
        let lengths = [NSNumber(value: tolerance), NSNumber(value: tolerance * 1.5)]
        polyline.spans = GMSStyleSpans(polyline.path!, pathStyles, lengths, .geodesic)

        prevLocation = newestLocation

        if isFollowingMe {
            MapView.animate(toLocation: newestLocation.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as NSError).domain == kCLErrorDomain.description {
            return // Ignore CoreLocation domain errors
        }

        let alert = UIAlertController(
            title: error.localizedDescription,
            message: "There was an error retrieving your location",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - GMSMapViewDelegate

extension GoogleMapsViewControllerSwift: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture {
            isFollowingMe = false
        }
    }

    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        isFollowingMe = true
        return false
    }
}

// MARK: - UICollectionViewDataSource

extension GoogleMapsViewControllerSwift: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bluetoothDiagnostics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let keys = bluetoothDiagnostics.keys.sorted()
        let key = keys[indexPath.row]

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath)

        if let keyLabel = cell.viewWithTag(1) as? UILabel {
            keyLabel.text = key
        }
        if let valLabel = cell.viewWithTag(2) as? UILabel {
            valLabel.text = "\(bluetoothDiagnostics[key] ?? 0)"
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension GoogleMapsViewControllerSwift: UICollectionViewDelegate {
    // Implement delegate methods if needed
}
