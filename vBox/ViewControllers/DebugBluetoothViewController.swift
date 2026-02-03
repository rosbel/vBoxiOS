//
//  DebugBluetoothViewController.swift
//  vBox
//
//  Swift implementation of BLE debug console
//

import UIKit
import Combine

// MARK: - Debug Bluetooth View Controller

final class DebugBluetoothViewControllerSwift: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var textView: UITextView!

    // MARK: - Properties

    private let bleManager = BLEManagerSwift()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bleManager.disconnect()
    }

    // MARK: - Setup

    private func setupUI() {
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.text = "BLE Debug Console\n" + String(repeating: "-", count: 40) + "\n"
    }

    private func setupBindings() {
        // Subscribe to BLE state changes
        bleManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)

        // Subscribe to diagnostics updates
        bleManager.diagnosticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] diagnostics in
                self?.logDiagnostics(diagnostics)
            }
            .store(in: &cancellables)

        // Subscribe to connection status
        bleManager.connectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.log(isConnected ? "Connected to device" : "Disconnected")
            }
            .store(in: &cancellables)
    }

    // MARK: - State Handling

    private func handleStateChange(_ state: BLEState) {
        log("State changed to: \(state.description)")

        if state == .on {
            log("Starting scan for OBD adapter...")
            _ = bleManager.scan(for: .obdAdapter)
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        let timestamp = DateDisplayFormatter.timeString(from: Date())
        let logLine = "[\(timestamp)] \(message)\n"

        textView.text.append(logLine)
        scrollToBottom()
    }

    private func logDiagnostics(_ diagnostics: VehicleDiagnostics) {
        var updates: [String] = []

        if let speed = diagnostics.speed {
            updates.append("Speed: \(Int(speed)) km/h")
        }
        if let rpm = diagnostics.rpm {
            updates.append("RPM: \(Int(rpm))")
        }
        if let fuel = diagnostics.fuelLevel {
            updates.append("Fuel: \(Int(fuel))%")
        }
        if let coolant = diagnostics.coolantTemp {
            updates.append("Coolant: \(Int(coolant))\u{00B0}C")
        }
        if let load = diagnostics.engineLoad {
            updates.append("Load: \(Int(load))%")
        }
        if let throttle = diagnostics.throttlePosition {
            updates.append("Throttle: \(Int(throttle))%")
        }

        if !updates.isEmpty {
            log(updates.joined(separator: " | "))
        }
    }

    private func scrollToBottom() {
        guard !textView.text.isEmpty else { return }
        let range = NSRange(location: textView.text.count - 1, length: 1)
        textView.scrollRangeToVisible(range)
    }

    // MARK: - Actions

    @IBAction private func clearLogTapped(_ sender: Any) {
        textView.text = "BLE Debug Console\n" + String(repeating: "-", count: 40) + "\n"
    }

    @IBAction private func reconnectTapped(_ sender: Any) {
        log("Reconnecting...")
        bleManager.disconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            _ = self?.bleManager.scan(for: .obdAdapter)
        }
    }
}

// MARK: - BLE State Description Extension

extension BLEState {
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
}
