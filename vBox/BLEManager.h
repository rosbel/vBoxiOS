//
//  BluetoothManager.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/31/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <Foundation/Foundation.h>

#define OBDAdapterServiceUID @"FFE0"
#define BeagleBoneServiceUID @"FFEF"

//!Types = PeripheralTypeOBDAdapter, PeripheralTypeBeagleBone
typedef NS_ENUM(NSInteger, PeripheralType) {
	PeripheralTypeOBDAdapter = 0,
	PeripheralTypeBeagleBone
};

typedef NS_ENUM(NSInteger, BLEState) {
	BLEStateOn = 0,
	BLEStateOff,
	BLEStateUnauthorized,
	BLEStateResetting,
	BLEStateUnkown,
	BLEStateUnsupported
};

@protocol BLEManagerDelegate <NSObject>
@optional

-(void)didBeginScanningForPeripheral;
-(void)didConnectPeripheral;
-(void)didDisconnectPeripheral;
-(void)didUpdateDebugLogWithString:(NSString *)string;

@required
/** States: BLEStateOn,BLEStateOff,BLEStateUnauthorized,BLEStateResetting,BLEStateUnkown,BLEStateUnsupported*/
-(void)didChangeBluetoothState:(BLEState)state;
-(void)didUpdateDiagnosticForKey:(NSString *)key withValue:(float)value;
-(void)didUpdateDiagnosticForKey:(NSString *)key withMultipleValues:(float[])values;

@end

@interface BLEManager : NSObject

@property (nonatomic, weak) id <BLEManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic) BLEState state;

//! @return NO if Bluetooth is not powered on. YES if Bluetooth is on
-(BOOL) scanForPeripheralType:(PeripheralType) type;
-(void) setNotifyValue:(BOOL)value;
-(void) disconnect;
@end
