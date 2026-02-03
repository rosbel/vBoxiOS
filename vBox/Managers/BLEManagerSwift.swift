//
//  BLEManager.swift
//  vBox
//
//  Modern Swift implementation of Bluetooth Low Energy manager for OBD-II communication
//

import Foundation
import CoreBluetooth
import Combine

// MARK: - BLE Manager Delegate Protocol

/// Swift protocol for BLE manager callbacks
@objc protocol BLEManagerSwiftDelegate: AnyObject {
    /// Called when Bluetooth state changes
    func bleManager(_ manager: BLEManagerSwift, didChangeState state: BLEState)

    /// Called when a diagnostic value is updated
    func bleManager(_ manager: BLEManagerSwift, didUpdateDiagnostic key: String, value: NSNumber)

    /// Called when scanning begins
    @objc optional func bleManagerDidBeginScanning(_ manager: BLEManagerSwift)

    /// Called when scanning stops
    @objc optional func bleManagerDidStopScanning(_ manager: BLEManagerSwift)

    /// Called when a peripheral is connected
    @objc optional func bleManagerDidConnect(_ manager: BLEManagerSwift)

    /// Called when a peripheral is disconnected
    @objc optional func bleManagerDidDisconnect(_ manager: BLEManagerSwift)

    /// Called with debug log messages
    @objc optional func bleManager(_ manager: BLEManagerSwift, didLogMessage message: String)
}

// MARK: - BLE Manager Swift

/// Modern Swift implementation of BLE manager for OBD-II adapters
@objc class BLEManagerSwift: NSObject {

    // MARK: - Singleton

    @objc static let shared = BLEManagerSwift()

    // MARK: - Published Properties (Combine)

    /// Current Bluetooth state
    @Published private(set) var state: BLEState = .unknown

    /// Whether currently connected to a peripheral
    @Published private(set) var isConnected: Bool = false

    /// Whether currently scanning
    @Published private(set) var isScanning: Bool = false

    /// Current vehicle diagnostics
    @Published private(set) var diagnostics = VehicleDiagnostics()

    /// Discovered peripherals during scanning
    @Published private(set) var discoveredPeripherals: [DiscoveredPeripheral] = []

    // MARK: - Delegate

    @objc weak var delegate: BLEManagerSwiftDelegate?

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager?
    private var connectedPeripheral: CBPeripheral?
    private var targetServiceUUID: CBUUID?
    private var dataCharacteristic: CBCharacteristic?

    private let centralQueue = DispatchQueue(label: "com.vbox.ble.central", qos: .userInitiated)
    private let peripheralQueue = DispatchQueue(label: "com.vbox.ble.peripheral", qos: .background)

    private var cancellables = Set<AnyCancellable>()

    // For BeagleBone peripheral mode
    private var advertisingCharacteristic: CBMutableCharacteristic?

    // MARK: - Initialization

    override init() {
        super.init()

        centralManager = CBCentralManager(
            delegate: self,
            queue: centralQueue,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )

        // Set up peripheral manager if BeagleBone connection is enabled
        if UserDefaults.standard.bool(forKey: "shouldConnectToBeagleBone") {
            peripheralManager = CBPeripheralManager(
                delegate: self,
                queue: peripheralQueue,
                options: [CBPeripheralManagerOptionShowPowerAlertKey: false]
            )
        }
    }

    // MARK: - Public Methods

    /// Start scanning for peripherals of the specified type
    /// - Parameter type: The type of peripheral to scan for
    /// - Returns: true if scanning started, false if Bluetooth is not ready
    @objc @discardableResult
    func scan(for type: PeripheralType) -> Bool {
        guard state == .on else {
            log("Cannot scan: Bluetooth state is \(state.description)")
            return false
        }

        targetServiceUUID = type.serviceUUID
        discoveredPeripherals.removeAll()

        log("Scanning for \(type.rawValue) peripherals...")

        centralManager.scanForPeripherals(
            withServices: [type.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        isScanning = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManagerDidBeginScanning?(self)
        }

        return true
    }

    /// Stop scanning for peripherals
    @objc func stopScanning() {
        centralManager.stopScan()
        isScanning = false

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManagerDidStopScanning?(self)
        }

        log("Stopped scanning")
    }

    /// Connect to a discovered peripheral
    /// - Parameter peripheral: The peripheral to connect to
    func connect(to peripheral: DiscoveredPeripheral) {
        // Find the CBPeripheral from our discovered list
        // In a real implementation, we'd store the CBPeripheral reference
        log("Connecting to \(peripheral.displayName)...")
    }

    /// Connect to a CBPeripheral directly
    @objc func connect(to peripheral: CBPeripheral) {
        log("Connecting to \(peripheral.name ?? "Unknown")...")

        centralManager.connect(
            peripheral,
            options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true]
        )
    }

    /// Disconnect from the current peripheral
    @objc func disconnect() {
        guard let peripheral = connectedPeripheral else {
            log("No peripheral connected")
            return
        }

        if peripheral.state == .connected {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    /// Enable or disable notifications for the data characteristic
    /// - Parameter enabled: Whether to enable notifications
    @objc func setNotifications(enabled: Bool) {
        guard let peripheral = connectedPeripheral,
              let characteristic = dataCharacteristic,
              peripheral.state == .connected else {
            log("Cannot set notifications: not connected")
            return
        }

        peripheral.setNotifyValue(enabled, for: characteristic)
        log("Notifications \(enabled ? "enabled" : "disabled")")
    }

    /// Stop advertising as a peripheral (BeagleBone mode)
    @objc func stopAdvertising() {
        guard let manager = peripheralManager, manager.isAdvertising else {
            return
        }

        manager.stopAdvertising()
        log("Stopped advertising")
    }

    // MARK: - Private Methods

    private func log(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManager?(self, didLogMessage: message)
        }

        #if DEBUG
        print("[BLE] \(message)")
        #endif
    }

    private func updateState(_ newState: BLEState) {
        state = newState

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManager(self, didChangeState: newState)
        }
    }

    private func processReceivedData(_ data: Data) {
        guard let packet = BLEDataPacket(data: data) else {
            log("Invalid packet received (checksum failed or invalid format)")
            return
        }

        guard let pid = packet.obdPID else {
            log("Unknown PID: 0x\(String(format: "%X", packet.pid)) = \(packet.primaryValue)")
            return
        }

        let reading = DiagnosticReading(pid: pid, value: packet.primaryValue)

        guard reading.isValid else {
            log("Invalid reading for \(pid.displayName): \(packet.primaryValue)")
            return
        }

        // Update our diagnostics snapshot
        diagnostics.update(with: reading)

        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManager(
                self,
                didUpdateDiagnostic: pid.displayName,
                value: NSNumber(value: reading.value)
            )
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManagerSwift: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let newState: BLEState

        switch central.state {
        case .poweredOn:
            newState = .on
        case .poweredOff:
            newState = .off
        case .resetting:
            newState = .resetting
        case .unauthorized:
            newState = .unauthorized
        case .unsupported:
            newState = .unsupported
        case .unknown:
            newState = .unknown
        @unknown default:
            newState = .unknown
        }

        log("Bluetooth state changed: \(newState.description)")
        updateState(newState)
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {

        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String

        guard localName != nil && !localName!.isEmpty else {
            return
        }

        log("Discovered: \(localName ?? peripheral.identifier.uuidString) (RSSI: \(RSSI))")

        // Stop scanning and connect
        centralManager.stopScan()
        isScanning = false

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManagerDidStopScanning?(self)
        }

        connectedPeripheral = peripheral
        peripheral.delegate = self

        centralManager.connect(
            peripheral,
            options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true]
        )
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("Connected to \(peripheral.name ?? "Unknown")")

        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManagerDidConnect?(self)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {

        log("Disconnected from \(peripheral.name ?? "Unknown")")

        isConnected = false
        connectedPeripheral = nil
        dataCharacteristic = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.bleManagerDidDisconnect?(self)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {

        log("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        connectedPeripheral = nil
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManagerSwift: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            log("Error discovering services: \(error!.localizedDescription)")
            return
        }

        guard let services = peripheral.services else {
            log("No services found")
            return
        }

        log("Discovered \(services.count) service(s)")

        for service in services {
            log("Service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        guard error == nil else {
            log("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else {
            log("No characteristics found for service \(service.uuid)")
            return
        }

        log("Discovered \(characteristics.count) characteristic(s)")

        for characteristic in characteristics {
            log("Characteristic: \(characteristic.uuid)")

            // Subscribe to notifications
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                dataCharacteristic = characteristic
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        if let error = error {
            log("Error receiving data: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            log("No data received")
            return
        }

        processReceivedData(data)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {

        if let error = error {
            log("Error updating notification state: \(error.localizedDescription)")
            return
        }

        log("Notifications \(characteristic.isNotifying ? "enabled" : "disabled") for \(characteristic.uuid)")
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLEManagerSwift: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            setupPeripheralService()
        default:
            break
        }
    }

    private func setupPeripheralService() {
        guard let manager = peripheralManager else { return }

        let serviceUUID = CBUUID(string: "FFEF")
        let characteristicUUID = CBUUID(string: "FFE1")

        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .write, .notify, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )

        advertisingCharacteristic = characteristic

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]

        manager.add(service)

        manager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "vBox",
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ])

        log("Started advertising as peripheral")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        log("Central subscribed to characteristic")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveRead request: CBATTRequest) {

        let value = advertisingCharacteristic?.value ?? "vBox".data(using: .utf8)!
        request.value = value
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveWrite requests: [CBATTRequest]) {

        for request in requests {
            advertisingCharacteristic?.value = request.value
            peripheral.respond(to: request, withResult: .success)
        }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let characteristic = advertisingCharacteristic,
              let value = characteristic.value else {
            return
        }

        peripheral.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
    }
}

// MARK: - Combine Extensions

extension BLEManagerSwift {

    /// Publisher for state changes
    var statePublisher: AnyPublisher<BLEState, Never> {
        $state.eraseToAnyPublisher()
    }

    /// Publisher for connection status changes
    var connectionPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }

    /// Publisher for diagnostic updates
    var diagnosticsPublisher: AnyPublisher<VehicleDiagnostics, Never> {
        $diagnostics.eraseToAnyPublisher()
    }

    /// Publisher for speed values
    var speedPublisher: AnyPublisher<Float?, Never> {
        $diagnostics
            .map { $0.speed }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Publisher for RPM values
    var rpmPublisher: AnyPublisher<Float?, Never> {
        $diagnostics
            .map { $0.rpm }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Publisher for fuel level values
    var fuelLevelPublisher: AnyPublisher<Float?, Never> {
        $diagnostics
            .map { $0.fuelLevel }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
