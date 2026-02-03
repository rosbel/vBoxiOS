//
//  BluetoothTableViewController.swift
//  vBox
//
//  Swift implementation of OBD diagnostics display
//

import UIKit
import Combine

// MARK: - Diagnostic Item

private struct DiagnosticItem: Comparable {
    let key: String
    let displayValue: String

    static func < (lhs: DiagnosticItem, rhs: DiagnosticItem) -> Bool {
        return lhs.key < rhs.key
    }
}

// MARK: - Bluetooth Table View Controller

final class BluetoothTableViewControllerSwift: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var startBarButton: UIBarButtonItem!
    @IBOutlet private weak var pauseBarButton: UIBarButtonItem!

    // MARK: - Properties

    private let bleManager = BLEManagerSwift()
    private var cancellables = Set<AnyCancellable>()
    private var diagnosticItems: [DiagnosticItem] = []
    private var spinner: UIActivityIndicatorView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupBindings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bleManager.disconnect()
    }

    // MARK: - Setup

    private func setupUI() {
        pauseBarButton.isEnabled = false

        // Setup spinner in navigation bar
        spinner = UIActivityIndicatorView(style: .medium)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DiagnosticCell")
    }

    private func setupBindings() {
        // Subscribe to BLE state changes
        bleManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)

        // Subscribe to connection status
        bleManager.connectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.handleConnectionChange(isConnected)
            }
            .store(in: &cancellables)

        // Subscribe to diagnostics
        bleManager.diagnosticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] diagnostics in
                self?.updateDiagnostics(diagnostics)
            }
            .store(in: &cancellables)

        // Subscribe to scanning status
        bleManager.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isScanning in
                self?.handleScanningChange(isScanning)
            }
            .store(in: &cancellables)
    }

    // MARK: - State Handling

    private func handleStateChange(_ state: BLEState) {
        spinner.stopAnimating()

        let title: String
        let enableStart: Bool

        switch state {
        case .on:
            title = "Bluetooth On"
            enableStart = true
        case .off:
            title = "Bluetooth Off"
            enableStart = false
        case .resetting:
            title = "Bluetooth Resetting"
            enableStart = false
        case .unauthorized:
            title = "Bluetooth Unauthorized"
            enableStart = false
        case .unknown:
            title = "Bluetooth Unknown"
            enableStart = false
        case .unsupported:
            title = "Bluetooth Unsupported"
            enableStart = false
        }

        navigationItem.title = title
        startBarButton.isEnabled = enableStart
        pauseBarButton.isEnabled = false
    }

    private func handleConnectionChange(_ isConnected: Bool) {
        spinner.stopAnimating()

        if isConnected {
            navigationItem.title = "Connected"
        } else {
            navigationItem.title = "Disconnected"
            pauseBarButton.isEnabled = false
            startBarButton.isEnabled = true
        }
    }

    private func handleScanningChange(_ isScanning: Bool) {
        if isScanning {
            spinner.startAnimating()
            navigationItem.title = "Scanning..."
        } else {
            spinner.stopAnimating()
            if bleManager.isConnected {
                navigationItem.title = "Connected"
            } else {
                navigationItem.title = "Not Connected"
            }
        }
    }

    // MARK: - Diagnostics Update

    private func updateDiagnostics(_ diagnostics: VehicleDiagnostics) {
        var items: [DiagnosticItem] = []

        if let speed = diagnostics.speed {
            items.append(DiagnosticItem(key: "Speed", displayValue: "\(Int(speed)) km/h"))
        }
        if let rpm = diagnostics.rpm {
            items.append(DiagnosticItem(key: "RPM", displayValue: "\(Int(rpm))"))
        }
        if let fuel = diagnostics.fuelLevel {
            items.append(DiagnosticItem(key: "Fuel Level", displayValue: "\(Int(fuel))%"))
        }
        if let coolant = diagnostics.coolantTemp {
            items.append(DiagnosticItem(key: "Coolant Temp", displayValue: "\(Int(coolant))\u{00B0}C"))
        }
        if let intake = diagnostics.intakeTemp {
            items.append(DiagnosticItem(key: "Intake Temp", displayValue: "\(Int(intake))\u{00B0}C"))
        }
        if let ambient = diagnostics.ambientTemp {
            items.append(DiagnosticItem(key: "Ambient Temp", displayValue: "\(Int(ambient))\u{00B0}C"))
        }
        if let load = diagnostics.engineLoad {
            items.append(DiagnosticItem(key: "Engine Load", displayValue: "\(Int(load))%"))
        }
        if let throttle = diagnostics.throttlePosition {
            items.append(DiagnosticItem(key: "Throttle", displayValue: "\(Int(throttle))%"))
        }
        if let barometric = diagnostics.barometricPressure {
            items.append(DiagnosticItem(key: "Barometric", displayValue: "\(Int(barometric)) kPa"))
        }
        if let distance = diagnostics.distanceSinceCodesCleared {
            items.append(DiagnosticItem(key: "Distance", displayValue: "\(Int(distance)) km"))
        }
        if let accel = diagnostics.accelerometer {
            items.append(DiagnosticItem(
                key: "Accelerometer",
                displayValue: "(\(String(format: "%.2f", accel.x)), \(String(format: "%.2f", accel.y)), \(String(format: "%.2f", accel.z)))"
            ))
        }

        diagnosticItems = items.sorted()
        tableView.reloadData()
    }

    // MARK: - Actions

    @IBAction private func startButtonPressed(_ sender: Any) {
        if bleManager.isConnected {
            bleManager.setNotifyValue(true)
        } else {
            _ = bleManager.scan(for: .obdAdapter)
        }

        startBarButton.isEnabled = false
        pauseBarButton.isEnabled = true
    }

    @IBAction private func pauseBarButtonPressed(_ sender: Any) {
        if bleManager.isConnected {
            bleManager.setNotifyValue(false)
        } else {
            bleManager.stopScanning()
        }

        startBarButton.isEnabled = true
        pauseBarButton.isEnabled = false
    }
}

// MARK: - UITableViewDataSource

extension BluetoothTableViewControllerSwift: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diagnosticItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiagnosticCell", for: indexPath)
        let item = diagnosticItems[indexPath.row]
        cell.textLabel?.text = "\(item.key) - \(item.displayValue)"
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BluetoothTableViewControllerSwift: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
