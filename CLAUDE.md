# CLAUDE.md - AI Assistant Guide for vBoxiOS

## Project Overview

**vBox** is an iOS application for vehicle trip logging that supports integration with OBD-II (On-Board Diagnostics) adapters via Bluetooth Low Energy (BLE). The app tracks driving metrics including GPS location, speed, distance, and when connected to a compatible OBD adapter, retrieves real-time vehicle diagnostics such as RPM, fuel level, engine load, and temperatures.

- **Platform**: iOS 13.0+ (required for Combine framework)
- **Languages**: Swift 5.0+ (modern) / Objective-C (legacy, being migrated)
- **License**: MIT
- **Author**: Rosbel Sanroman

## Repository Structure

```
vBoxiOS/
├── vBox/                       # Main application source code
│   ├── AppDelegate.{h,m}       # App lifecycle, Core Data stack
│   │
│   ├── # Swift Models (Modern)
│   ├── Models/
│   │   ├── OBDTypes.swift      # OBD-II protocol types (PIDs, packets, diagnostics)
│   │   ├── BLETypes.swift      # BLE state, connection types, errors
│   │   └── CoreData/           # Swift Core Data entity classes
│   │       ├── TripEntity.swift
│   │       ├── GPSLocationEntity.swift
│   │       ├── BluetoothDataEntity.swift
│   │       └── DrivingHistoryEntity.swift
│   │
│   ├── # Swift Managers (Modern)
│   ├── Managers/
│   │   └── BLEManagerSwift.swift  # Modern BLE manager with Combine
│   │
│   ├── # Swift Utilities (Modern)
│   ├── Utilities/
│   │   └── DateFormatting.swift   # Duration and date formatting
│   │
│   ├── # Swift View Controllers (Modern)
│   ├── ViewControllers/
│   │   ├── GoogleMapsViewController.swift  # Trip recording with map
│   │   ├── MainScreenViewController.swift  # Home screen navigation
│   │   ├── TripDetailViewController.swift  # Trip playback with scrubber
│   │   ├── DrivingHistoryViewController.swift  # Trip list by date
│   │   ├── BluetoothTableViewController.swift  # OBD diagnostic display
│   │   └── DebugBluetoothViewController.swift  # BLE debug console
│   │
│   ├── # Objective-C Legacy (for reference)
│   ├── BLEManager.{h,m}        # Legacy BLE manager
│   ├── GoogleMapsViewController.{h,m}  # Legacy - see ViewControllers/
│   ├── MainScreenViewController.{h,m}  # Legacy - see ViewControllers/
│   ├── TripDetailViewController.{h,m}  # Legacy - see ViewControllers/
│   ├── DrivingHistoryViewController.{h,m}  # Legacy - see ViewControllers/
│   ├── BluetoothTableViewController.{h,m}  # Legacy - see ViewControllers/
│   ├── DebugBluetoothViewController.{h,m}  # Legacy - see ViewControllers/
│   │
│   ├── # Legacy Data Models (Objective-C)
│   ├── Trip.{h,m}, GPSLocation.{h,m}, BluetoothData.{h,m}, DrivingHistory.{h,m}
│   │
│   ├── # Third-Party Libraries
│   ├── WMGaugeView.{h,m}       # Gauge UI component
│   ├── OBSlider.{h,m}          # Scrubber slider
│   ├── SVProgressHUD.{h,m}     # Progress indicator
│   ├── MyStyleKit.{h,m}        # PaintCode drawings
│   │
│   ├── # Bridging Headers
│   ├── vBox-Bridging-Header.h  # Swift/Obj-C interop
│   │
│   └── # Resources
│       ├── Base.lproj/Main.storyboard
│       ├── GPSInformation.xcdatamodeld/
│       ├── Images.xcassets/
│       └── Info.plist
│
├── vBoxTests/                  # Unit tests (Swift)
│   ├── OBDTypesTests.swift     # OBD protocol tests
│   ├── BLETypesTests.swift     # BLE types tests
│   ├── BLEManagerSwiftTests.swift  # BLE manager tests
│   ├── CoreDataModelTests.swift    # Core Data tests
│   ├── DateFormattingTests.swift   # Formatting tests
│   └── TestHelpers.swift       # Test utilities
│
├── Pods/                       # CocoaPods dependencies
├── vBox.xcworkspace/           # Use this for development
├── Podfile                     # Dependencies
└── Podfile.lock
```

## Architecture

### Modern Swift Components

#### OBDTypes (`Models/OBDTypes.swift`)
- `OBDPID` enum - All supported OBD-II parameter IDs with validation
- `BLEDataPacket` - 12-byte packet parsing with checksum
- `DiagnosticReading` - Validated diagnostic value with display formatting
- `VehicleDiagnostics` - Snapshot of all vehicle data
- `AccelerometerReading` - 3-axis acceleration data

#### BLETypes (`Models/BLETypes.swift`)
- `BLEState` - Bluetooth adapter states
- `PeripheralType` - OBD adapter vs BeagleBone
- `ConnectionState` - Connection lifecycle
- `DiscoveredPeripheral` - Discovered device info
- `SignalStrength` - RSSI categorization
- `BLEError` - Typed errors with descriptions

#### BLEManagerSwift (`Managers/BLEManagerSwift.swift`)
- Modern Combine-based BLE manager
- Publishers: `$state`, `$isConnected`, `$diagnostics`
- Convenience publishers: `speedPublisher`, `rpmPublisher`, `fuelLevelPublisher`
- Thread-safe with dedicated dispatch queues
- Delegate protocol for Objective-C compatibility

#### Core Data Swift Models (`Models/CoreData/`)
- `TripEntity` - Trip with computed duration, distance, path coordinates
- `GPSLocationEntity` - Location with CLLocation conversion, distance/bearing
- `BluetoothDataEntity` - OBD diagnostics with temperature monitoring
- `DrivingHistoryEntity` - Trip management and statistics

#### Swift View Controllers (`ViewControllers/`)
| Controller | Purpose |
|------------|---------|
| `GoogleMapsViewControllerSwift` | Trip recording with GPS and BLE using Combine |
| `MainScreenViewControllerSwift` | Home screen with button styling |
| `TripDetailViewControllerSwift` | Trip playback with map, gauges, and scrubber |
| `DrivingHistoryViewControllerSwift` | Trip list grouped by date |
| `BluetoothTableViewControllerSwift` | OBD diagnostic display using Combine |
| `DebugBluetoothViewControllerSwift` | BLE debug console with Combine |

### Legacy Objective-C Components

#### AppDelegate
- Core Data stack management
- Google Maps SDK initialization
- Singleton `DrivingHistory` access

#### Legacy View Controllers (being replaced)
| Controller | Purpose |
|------------|---------|
| `GoogleMapsViewController` | Legacy - use Swift version |
| `MainScreenViewController` | Legacy - use Swift version |
| `TripDetailViewController` | Legacy - use Swift version |
| `DrivingHistoryViewController` | Legacy - use Swift version |
| `BluetoothTableViewController` | Legacy - use Swift version |
| `DebugBluetoothViewController` | Legacy - use Swift version |

### Data Model (Core Data)

```
DrivingHistory (root)
    └── trips (ordered, to-many) → Trip
            ├── startTime, endTime
            ├── avgSpeed, maxSpeed, minSpeed
            ├── totalMiles, tripName
            └── gpsLocations (ordered, to-many) → GPSLocation
                    ├── latitude, longitude, altitude
                    ├── speed, metersFromStart, timestamp
                    └── bluetoothInfo (optional, to-one) → BluetoothData
                            └── speed, rpm, fuel, coolantTemp, engineLoad,
                                throttle, intakeTemp, ambientTemp, barometric,
                                distance, accelX, accelY, accelZ
```

### Dependencies

**CocoaPods (Podfile)**:
- `GoogleMaps` - Maps SDK for iOS

**Bundled Third-Party Libraries**:
- `WMGaugeView` - Animated gauge visualization
- `OBSlider` - Slider with scrubbing support
- `SVProgressHUD` - Progress/loading indicator

## Development Workflow

### Opening the Project
```bash
# Always use the workspace for CocoaPods support
open vBox.xcworkspace
```

### Building
1. Open `vBox.xcworkspace` in Xcode
2. Select the `vBox` scheme
3. Choose a simulator or device target
4. Build with Cmd+B or Run with Cmd+R

### Running Tests
```bash
# Run all tests
xcodebuild test -workspace vBox.xcworkspace -scheme vBox -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Dependencies
```bash
gem install cocoapods
pod install
```

### System Requirements
- iOS 13.0+ deployment target (for Combine framework support)
- Xcode 14+ (for Swift 5 and iOS 13+ SDK)
- CocoaPods 1.10+

## Key Conventions

### Swift Style (Modern Code)
- Use `@Published` properties with Combine for reactive updates
- Prefer value types (`struct`, `enum`) over classes where appropriate
- Use `async/await` for asynchronous operations
- Create factory methods on types (e.g., `TripEntity.create(in:)`)
- Add computed properties for common conversions

### Objective-C Style (Legacy Code)
- Properties use `@synthesize` with underscore prefix ivars
- Delegate protocols defined in header files
- `#pragma mark -` sections for code organization

### Bluetooth Communication
- BLE operations run on dedicated serial queues
- Data validation via checksum before processing
- PID values defined in `OBDPID` enum (Swift) or hex constants (Obj-C)

### Core Data
- Main context uses `NSMainQueueConcurrencyType`
- Automatic lightweight migration enabled
- SQLite store at `Documents/GPSInformation.sqlite`
- Use Swift entity classes for new code

### Testing
- All new Swift code should have corresponding tests
- Use in-memory Core Data context for tests
- Test helpers in `TestHelpers.swift`

## Important Notes for AI Assistants

### Code Modifications
1. **Prefer Swift**: Write new code in Swift, not Objective-C
2. **Use the workspace**: Always work with `vBox.xcworkspace`
3. **Add tests**: All new Swift code needs test coverage
4. **Core Data migrations**: Adding model attributes requires a new model version

### Testing Considerations
- BLE functionality requires a physical device
- GPS simulation available in Xcode for location testing
- OBD adapter integration requires Freematics hardware
- Use `CoreDataTestCase` base class for database tests

### File Naming
- Swift files: `TypeName.swift`
- Swift tests: `TypeNameTests.swift`
- Objective-C pairs: `ClassName.h` / `ClassName.m`
- Core Data model: `GPSInformation.xcdatamodeld`

### OBD-II Protocol
The BLEManager supports Freematics OBD adapters with a custom binary protocol:
- 12-byte packets with XOR checksum validation
- PIDs defined in `OBDPID` enum with display names and max values
- Data structure: `{time: UInt32, pid: UInt16, flags: UInt8, checksum: UInt8, value: Float}`

## Common Tasks

### Adding a New Swift Type
1. Create `TypeName.swift` in appropriate directory
2. Create `TypeNameTests.swift` in `vBoxTests/`
3. Add to bridging header if needed for Obj-C access

### Using the Modern BLE Manager
```swift
// Subscribe to diagnostics
BLEManagerSwift.shared.diagnosticsPublisher
    .sink { diagnostics in
        print("Speed: \(diagnostics.speed ?? 0)")
    }
    .store(in: &cancellables)

// Start scanning
BLEManagerSwift.shared.scan(for: .obdAdapter)
```

### Working with Core Data in Swift
```swift
// Create a new trip
let trip = TripEntity.create(in: context)
trip.tripName = "Morning Commute"

// Add a location
let location = GPSLocationEntity.create(in: context, from: clLocation)
trip.addToGpsLocations(location)

// Calculate statistics
trip.calculateStatistics()
```
