# CLAUDE.md - AI Assistant Guide for vBoxiOS

## Project Overview

**vBox** is an iOS application for vehicle trip logging that supports integration with OBD-II (On-Board Diagnostics) adapters via Bluetooth Low Energy (BLE). The app tracks driving metrics including GPS location, speed, distance, and when connected to a compatible OBD adapter, retrieves real-time vehicle diagnostics such as RPM, fuel level, engine load, and temperatures.

- **Platform**: iOS (minimum iOS 8.1)
- **Language**: Objective-C
- **License**: MIT
- **Author**: Rosbel Sanroman

## Repository Structure

```
vBoxiOS/
├── vBox/                       # Main application source code
│   ├── AppDelegate.{h,m}       # App lifecycle, Core Data stack, Push notifications
│   ├── BLEManager.{h,m}        # Bluetooth Low Energy manager for OBD communication
│   ├── GoogleMapsViewController.{h,m}  # Main driving view with map and gauges
│   ├── MainScreenViewController.{h,m}  # Home screen
│   ├── TripDetailViewController.{h,m}  # Trip playback and review
│   ├── DrivingHistoryViewController.{h,m}  # List of recorded trips
│   ├── BluetoothTableViewController.{h,m}  # BLE device selection
│   ├── DebugBluetoothViewController.{h,m}  # BLE debugging interface
│   │
│   ├── # Data Models (Core Data NSManagedObject subclasses)
│   ├── Trip.{h,m}              # Trip entity with metadata
│   ├── GPSLocation.{h,m}       # GPS coordinate entity
│   ├── BluetoothData.{h,m}     # OBD diagnostic data entity
│   ├── DrivingHistory.{h,m}    # Root container for trips
│   │
│   ├── # Utilities & Third-Party
│   ├── UtilityMethods.{h,m}    # Date formatting helpers
│   ├── WMGaugeView.{h,m}       # Gauge UI component (third-party)
│   ├── OBSlider.{h,m}          # Scrubber slider (third-party)
│   ├── SVProgressHUD.{h,m}     # Progress indicator (third-party)
│   ├── MyStyleKit.{h,m}        # PaintCode-generated drawing code
│   │
│   ├── # Resources
│   ├── Base.lproj/Main.storyboard  # Main UI storyboard
│   ├── Base.lproj/LaunchScreen.xib # Launch screen
│   ├── GPSInformation.xcdatamodeld/ # Core Data model
│   ├── Images.xcassets/        # Image assets
│   ├── Settings.bundle/        # iOS Settings integration
│   └── Info.plist              # App configuration
│
├── vBoxTests/                  # Unit tests
├── Pods/                       # CocoaPods dependencies
├── *.framework/                # Vendored frameworks (Parse, Bolts, ParseCrashReporting)
├── vBox.xcodeproj/             # Xcode project
├── vBox.xcworkspace/           # Xcode workspace (use this for development)
├── Podfile                     # CocoaPods dependency specification
└── Podfile.lock                # Locked dependency versions
```

## Architecture

### Core Components

#### AppDelegate (`AppDelegate.{h,m}`)
- Manages the Core Data stack (NSManagedObjectContext, NSPersistentStoreCoordinator)
- Initializes Google Maps SDK and Parse SDK
- Handles push notification registration and processing
- Provides access to the singleton `DrivingHistory` object

#### BLEManager (`BLEManager.{h,m}`)
- Singleton-style Bluetooth Low Energy manager
- Implements `CBCentralManagerDelegate` and `CBPeripheralDelegate`
- Scans for and connects to OBD adapters (service UUID: `FFE0`)
- Parses OBD-II PID data from the Freematics adapter
- Supports PIDs: Speed, RPM, Fuel, Coolant Temp, Engine Load, Throttle, Intake Temp, etc.
- Uses checksum validation for data integrity

#### View Controllers
| Controller | Purpose |
|------------|---------|
| `MainScreenViewController` | App home screen with navigation buttons |
| `GoogleMapsViewController` | Live trip recording with map and diagnostic gauges |
| `TripDetailViewController` | Trip playback with timeline scrubber |
| `DrivingHistoryViewController` | Table view of all recorded trips |
| `BluetoothTableViewController` | BLE peripheral discovery and selection |
| `DebugBluetoothViewController` | Debug console for BLE communication |

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

**Vendored Frameworks**:
- `Parse.framework` - Backend-as-a-Service (deprecated)
- `Bolts.framework` - Task/promise library (Parse dependency)
- `ParseCrashReporting.framework` - Crash reporting

**Bundled Third-Party Libraries**:
- `WMGaugeView` - Animated gauge visualization
- `OBSlider` - Slider with scrubbing support
- `SVProgressHUD` - Progress/loading indicator

## Development Workflow

### Opening the Project
```bash
# Always use the workspace (not the .xcodeproj) for CocoaPods support
open vBox.xcworkspace
```

### Building
1. Open `vBox.xcworkspace` in Xcode
2. Select the `vBox` scheme
3. Choose a simulator or device target
4. Build with Cmd+B or Run with Cmd+R

### Dependencies
```bash
# Install CocoaPods if needed
gem install cocoapods

# Install/update dependencies
pod install
```

### Requirements
- Xcode (with iOS SDK)
- CocoaPods
- Google Maps API key (configured in AppDelegate.m)

## Key Conventions

### Objective-C Style
- Properties use `@synthesize` with underscore prefix ivars
- Delegate protocols defined in header files
- `#pragma mark -` sections for code organization
- Async operations dispatch to main thread for UI updates

### Bluetooth Communication
- BLE operations run on dedicated serial queues (`bluetoothThread`, `peripheralThread`)
- Data validation via checksum before processing
- PID values defined as hex constants (e.g., `#define PID_RPM 0x10C`)
- Delegate pattern for communicating state changes

### Core Data
- Main context uses `NSMainQueueConcurrencyType`
- Automatic lightweight migration enabled
- SQLite store at `Documents/GPSInformation.sqlite`

### Background Modes
The app requires these background capabilities (Info.plist):
- `bluetooth-central` - BLE communication
- `bluetooth-peripheral` - BLE advertising
- `location` - GPS tracking
- `remote-notification` - Push notifications

## Important Notes for AI Assistants

### Code Modifications
1. **Always use the workspace**: Changes must be made with `vBox.xcworkspace` context
2. **Objective-C patterns**: Follow existing delegate and category patterns
3. **Core Data migrations**: Adding model attributes requires a new model version
4. **API Keys**: The codebase contains hardcoded API keys for Google Maps and Parse - these should be moved to configuration files in production

### Testing Considerations
- BLE functionality requires a physical device
- GPS simulation available in Xcode for location testing
- OBD adapter integration requires Freematics hardware

### Deprecated Components
- **Parse SDK**: Parse shut down in 2017; this integration is non-functional
- Consider removing Parse dependencies and related code if modernizing

### File Naming
- Header/implementation pairs: `ClassName.h` / `ClassName.m`
- Categories use `+` syntax: `UINavigationController+Orientation.{h,m}`
- Core Data model: `GPSInformation.xcdatamodeld`

### OBD-II Protocol
The BLEManager supports Freematics OBD adapters with a custom binary protocol:
- 12-byte packets with checksum validation
- PIDs map to standard OBD-II parameters
- Data structure: `{time, pid, flags, checksum, value[3]}`

## Common Tasks

### Adding a New View Controller
1. Create `NewViewController.h` and `NewViewController.m` in `vBox/`
2. Add to Main.storyboard or create programmatically
3. Follow existing patterns for delegate protocols

### Adding a Core Data Entity
1. Open `GPSInformation.xcdatamodeld`
2. Add new model version (Editor > Add Model Version)
3. Create corresponding `NSManagedObject` subclass files

### Modifying BLE Data Handling
1. Add PID constant in `BLEManager.m`
2. Add case in `peripheral:didUpdateValueForCharacteristic:error:`
3. Call `asyncUpdateDiagnosticForKey:withValue:ifUnderLimit:`
