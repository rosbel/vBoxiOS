//
//  TripDetailViewController.swift
//  vBox
//
//  Swift implementation of trip playback view
//

import UIKit
import GoogleMaps
import MessageUI

// MARK: - Trip Detail View Controller

final class TripDetailViewControllerSwift: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var mapView: GMSMapView!
    @IBOutlet private weak var tripSlider: OBSlider!
    @IBOutlet private weak var speedLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var speedGauge: WMGaugeView!
    @IBOutlet private weak var RPMGauge: WMGaugeView!
    @IBOutlet private weak var fuelGauge: WMGaugeView!
    @IBOutlet private weak var speedometerIcon: UIImageView!
    @IBOutlet private weak var fullScreenButton: UIButton!
    @IBOutlet private weak var followMeButton: UIButton!

    // MARK: - Properties

    var trip: Trip!

    private let pathColors: [UIColor] = [.red, .orange, .yellow, .green]
    private var speedDivisions: [Double] = []
    private var gpsLocations: [GPSLocation] = []
    private var pathForTrip: GMSMutablePath!
    private var markerForSlider: GMSMarker?
    private var markerForTap: GMSMarker?
    private var cameraBounds: GMSCoordinateBounds!
    private var isFollowingMe = false
    private var showRealTime = false

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTripData()
        setupGoogleMaps()
        setupGauges()
        setupSlider()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let update = GMSCameraUpdate.fit(cameraBounds, withPadding: 40)
        mapView.animate(with: update)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    // MARK: - Setup

    private func setupUI() {
        speedometerIcon.image = MyStyleKit.image(ofSpeedometerWithStrokeColor: .white)

        let buttonImage = MyStyleKit.image(ofVBoxButtonWithButtonColor: .white)
        fullScreenButton.setBackgroundImage(buttonImage, for: .normal)
        followMeButton.setBackgroundImage(buttonImage, for: .normal)

        fullScreenButton.layer.masksToBounds = true
        fullScreenButton.layer.cornerRadius = 5.0

        followMeButton.layer.masksToBounds = true
        followMeButton.layer.cornerRadius = 5.0

        // Setup time label tap gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTimeLabel))
        timeLabel.isUserInteractionEnabled = true
        timeLabel.addGestureRecognizer(tapRecognizer)

        followMeButton.isHidden = true
    }

    private func loadTripData() {
        guard let locations = trip.gpsLocations else {
            gpsLocations = []
            return
        }
        gpsLocations = locations.array as? [GPSLocation] ?? []
    }

    private func setupGoogleMaps() {
        mapView.padding = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)

        pathForTrip = GMSMutablePath()

        var spanStyles: [GMSStyleSpan] = []
        var segments: Double = 1
        var currentColor: UIColor?
        var newColor: UIColor?

        guard gpsLocations.count >= 2,
              let start = gpsLocations.first,
              let end = gpsLocations.last else {
            return
        }

        // Create start and end markers
        let startCoord = CLLocationCoordinate2D(latitude: start.latitude?.doubleValue ?? 0,
                                                 longitude: start.longitude?.doubleValue ?? 0)
        let endCoord = CLLocationCoordinate2D(latitude: end.latitude?.doubleValue ?? 0,
                                               longitude: end.longitude?.doubleValue ?? 0)

        let startMarker = GMSMarker(position: startCoord)
        let endMarker = GMSMarker(position: endCoord)

        startMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        endMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)

        startMarker.map = mapView
        endMarker.map = mapView

        startMarker.icon = UIImage(named: "startPosition")
        endMarker.icon = UIImage(named: "endPosition")

        // Calculate speed boundaries
        speedDivisions = calculateSpeedBoundaries()

        // Build path with color segments
        for gpsLoc in gpsLocations {
            let lat = gpsLoc.latitude?.doubleValue ?? 0
            let lon = gpsLoc.longitude?.doubleValue ?? 0
            pathForTrip.add(CLLocationCoordinate2D(latitude: lat, longitude: lon))

            let speed = gpsLoc.speed?.doubleValue ?? 0

            for (index, bound) in speedDivisions.enumerated() {
                if speed <= bound {
                    newColor = pathColors[index]
                    if newColor == currentColor {
                        segments += 1
                    } else {
                        spanStyles.append(GMSStyleSpan(color: currentColor ?? newColor ?? .green, segments: segments))
                        segments = 1
                    }
                    currentColor = newColor
                    break
                }
            }
        }

        // Create polyline
        let polyline = GMSPolyline(path: pathForTrip)
        polyline.strokeWidth = 5
        polyline.spans = spanStyles
        polyline.geodesic = true
        polyline.map = mapView

        // Setup camera
        cameraBounds = GMSCoordinateBounds(path: pathForTrip)
        let camera = mapView.camera(for: cameraBounds, insets: .zero)

        let zoom = (camera?.zoom ?? 10) > 5 ? (camera?.zoom ?? 10) - 4 : (camera?.zoom ?? 10)
        mapView.camera = GMSCameraPosition(latitude: startCoord.latitude,
                                           longitude: startCoord.longitude,
                                           zoom: zoom,
                                           bearing: 120,
                                           viewingAngle: 25)
        mapView.settings.compassButton = true
        mapView.isMyLocationEnabled = false
        mapView.delegate = self
    }

    private func setupGauges() {
        speedGauge.setUp(withUnits: "MPH", max: 150, startAngle: 90, endAngle: 270)
        fuelGauge.setUp(withUnits: "Fuel %", max: 100, startAngle: 90, endAngle: 270)
        RPMGauge.setUp(withUnits: "RPM", max: 10000, startAngle: 90, endAngle: 270)
    }

    private func setupSlider() {
        guard !gpsLocations.isEmpty else { return }
        tripSlider.maximumValue = Float(gpsLocations.count - 1)
    }

    // MARK: - Helper Methods

    private func calculateSpeedBoundaries() -> [Double] {
        let maxSpeed = trip.maxSpeed?.doubleValue ?? 0
        let minSpeed = trip.minSpeed?.doubleValue ?? 0

        var colorDivision: [Double] = []
        for i in 0..<(pathColors.count - 1) {
            let bound = (minSpeed + Double(i + 1) * (maxSpeed - minSpeed)) / Double(pathColors.count)
            colorDivision.append(bound)
        }
        colorDivision.append(maxSpeed)
        return colorDivision
    }

    private func updateMarkerForSlider(with location: GPSLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude?.doubleValue ?? 0,
                                                 longitude: location.longitude?.doubleValue ?? 0)
        if markerForSlider == nil {
            markerForSlider = GMSMarker(position: coordinate)
            markerForSlider?.icon = UIImage(named: "currentLocation")
            markerForSlider?.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            markerForSlider?.map = mapView
            followMeButton.isHidden = false
        } else {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.001)
            markerForSlider?.position = coordinate
            CATransaction.commit()
        }

        if isFollowingMe {
            mapView.animate(toLocation: coordinate)
        }
    }

    private func updateTapMarker(in mapView: GMSMapView, with location: GPSLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude?.doubleValue ?? 0,
                                                 longitude: location.longitude?.doubleValue ?? 0)
        if markerForTap == nil {
            markerForTap = GMSMarker(position: coordinate)
            markerForTap?.map = mapView
            markerForTap?.appearAnimation = .pop
        }

        markerForTap?.position = coordinate
        let timestampString = location.timestamp.map { dateFormatter.string(from: $0) } ?? "--:--"
        markerForTap?.snippet = "Time: \(timestampString)\nSpeed: \(String(format: "%.2f", location.speed?.doubleValue ?? 0))"
    }

    // MARK: - Actions

    @IBAction private func sliderValueChanged(_ sender: UISlider) {
        let value = Int(round(sender.value))
        guard value < gpsLocations.count else { return }

        let location = gpsLocations[value]

        // Update time label
        if showRealTime {
            timeLabel.text = location.timestamp.map { dateFormatter.string(from: $0) } ?? "--:--"
        } else if let startTime = trip.startTime, let timestamp = location.timestamp {
            timeLabel.text = DurationFormatter.string(from: timestamp.timeIntervalSince(startTime))
        }

        // Update speed and distance labels
        let speed = location.speed?.doubleValue ?? 0
        let metersFromStart = location.metersFromStart?.doubleValue ?? 0
        speedLabel.text = String(format: "%.2fmph", speed)
        distanceLabel.text = String(format: "%.2fmi", metersFromStart * 0.000621371)

        // Update gauges
        speedGauge.setValue(Float(speed), animated: false)

        if let bluetoothInfo = location.bluetoothInfo {
            RPMGauge.isHidden = false
            fuelGauge.isHidden = false

            let rpm = bluetoothInfo.rpm?.floatValue ?? 0
            let fuel = bluetoothInfo.fuel?.floatValue ?? 0
            let btSpeed = bluetoothInfo.speed?.floatValue ?? Float(speed)

            RPMGauge.setValue(rpm, animated: false)
            fuelGauge.setValue(fuel, animated: false)
            speedGauge.setValue(btSpeed, animated: false)
        }

        updateMarkerForSlider(with: location)
    }

    @IBAction private func fullScreenButtonTapped(_ sender: UIButton) {
        let update = GMSCameraUpdate.fit(cameraBounds, withPadding: 40)
        mapView.animate(with: update)
    }

    @IBAction private func followMeButtonTapped(_ sender: UIButton) {
        isFollowingMe.toggle()

        if isFollowingMe {
            sender.setImage(UIImage(named: "followMeOn"), for: .normal)
            if let position = markerForSlider?.position {
                mapView.animate(toLocation: position)
            }
        } else {
            sender.setImage(UIImage(named: "followMeOff"), for: .normal)
        }
    }

    @objc private func didTapTimeLabel() {
        showRealTime.toggle()
        sliderValueChanged(tripSlider)
    }

    @IBAction private func shareButtonTapped(_ sender: Any) {
        let logContent = generateTripLogString()

        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let fileURL = path.appendingPathComponent("trip.log")

        do {
            // Remove previous file if exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            // Write new log file
            try logContent.write(to: fileURL, atomically: true, encoding: .utf8)

            // Present mail composer
            if MFMailComposeViewController.canSendMail() {
                let composer = MFMailComposeViewController()
                composer.mailComposeDelegate = self
                composer.setSubject("Trip logged with vBox")

                if let data = FileManager.default.contents(atPath: fileURL.path) {
                    composer.addAttachmentData(data, mimeType: "text/plain", fileName: "myTrip.log")
                }

                let htmlBody = """
                Click <a href="http://students.cse.tamu.edu/crapier">here</a> and upload your file to view your log in more detail!
                <br>Brought to you by vBox.
                """
                composer.setMessageBody(htmlBody, isHTML: true)

                present(composer, animated: true) {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            } else {
                SVProgressHUD.showError(withStatus: "This device cannot send mail!")
            }
        } catch {
            SVProgressHUD.showError(withStatus: "Failed to create log file")
        }
    }

    private func generateTripLogString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"

        var log = "Timestamp Lat Long Distance-mi Speed-MPH Altitude-ft RPM-RPM Throttle-% EngineLoad-% Fuel-% Barometric-kPa AmbientTemperature-C CoolantTemperature-C, IntakeTemperature-C, Distance-km\n"

        for location in gpsLocations {
            let timestamp = location.timestamp.map { formatter.string(from: $0) } ?? "0"
            let lat = location.latitude?.doubleValue ?? 0
            let lon = location.longitude?.doubleValue ?? 0
            let distance = (location.metersFromStart?.doubleValue ?? 0) * 0.000621371

            log += "\(timestamp) \(lat) \(lon) \(distance)"

            if let bt = location.bluetoothInfo {
                let speed = bt.speed?.stringValue ?? location.speed?.stringValue ?? "XX"
                let altitude = location.altitude?.doubleValue ?? 0
                let rpm = bt.rpm?.stringValue ?? "XX"
                let throttle = bt.throttle?.stringValue ?? "XX"
                let engineLoad = bt.engineLoad?.stringValue ?? "XX"
                let fuel = bt.fuel?.stringValue ?? "XX"
                let barometric = bt.barometric?.stringValue ?? "XX"
                let ambient = bt.ambientTemp?.stringValue ?? "XX"
                let coolant = bt.coolantTemp?.stringValue ?? "XX"
                let intake = bt.intakeTemp?.stringValue ?? "XX"
                let btDistance = bt.distance?.stringValue ?? "XX"

                log += " \(speed) \(altitude) \(rpm) \(throttle) \(engineLoad) \(fuel) \(barometric) \(ambient) \(coolant) \(intake) \(btDistance)"
            } else {
                let speed = location.speed?.stringValue ?? "XX"
                let altitude = location.altitude?.doubleValue ?? 0
                log += " \(speed) \(altitude) XX XX XX XX XX XX XX XX XX"
            }
            log += "\n"
        }

        return log
    }
}

// MARK: - GMSMapViewDelegate

extension TripDetailViewControllerSwift: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture && isFollowingMe {
            followMeButtonTapped(followMeButton)
        }
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        let tolerance = pow(10.0, (-0.301 * Double(mapView.camera.zoom)) + 9.0731) / 500

        guard GMSGeometryIsLocationOnPath(coordinate, pathForTrip, false, tolerance) else {
            return
        }

        var closestLocation: GPSLocation?
        var closestDistance = CLLocationDistanceMax

        for location in gpsLocations {
            let coord = CLLocationCoordinate2D(latitude: location.latitude?.doubleValue ?? 0,
                                                longitude: location.longitude?.doubleValue ?? 0)
            let distance = GMSGeometryDistance(coord, coordinate)
            if distance < closestDistance {
                closestDistance = distance
                closestLocation = location
            }
        }

        if let location = closestLocation {
            updateTapMarker(in: mapView, with: location)
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension TripDetailViewControllerSwift: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true) {
            switch result {
            case .cancelled:
                SVProgressHUD.showError(withStatus: "Canceled")
            case .failed:
                SVProgressHUD.showError(withStatus: "Something went wrong :(")
            case .saved:
                SVProgressHUD.showSuccess(withStatus: "Saved!")
            case .sent:
                SVProgressHUD.showSuccess(withStatus: "Sent!")
            @unknown default:
                break
            }
        }
    }
}
