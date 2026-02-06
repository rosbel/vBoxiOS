//
//  vBoxTests-Bridging-Header.h
//  vBoxTests
//
//  Bridging header for test target to access Objective-C code
//

#ifndef vBoxTests_Bridging_Header_h
#define vBoxTests_Bridging_Header_h

// Core Data Models
#import "DrivingHistory.h"
#import "Trip.h"
#import "GPSLocation.h"
#import "BluetoothData.h"

// Managers
#import "BLEManager.h"

// View Controllers
#import "AppDelegate.h"
#import "MainScreenViewController.h"
#import "GoogleMapsViewController.h"
#import "TripDetailViewController.h"
#import "DrivingHistoryViewController.h"
#import "BluetoothTableViewController.h"
#import "DebugBluetoothViewController.h"

// Utilities
#import "UtilityMethods.h"

// Third-party
#import "WMGaugeView.h"
#import "OBSlider.h"
#import "SVProgressHUD.h"

#endif /* vBoxTests_Bridging_Header_h */
