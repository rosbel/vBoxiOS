//
//  BluetoothCentral.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/16/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BluetoothControllerDelegate <NSObject>

@optional
-(void)didUpdateLogWithString:(NSString *)string;
-(void)didFindPeripheral;
-(void)didConnectToPeripheral;
-(void)didDisconnectPeripheral;
-(void)bluetoothStateChangedTo:(NSString *)state;

@required
-(void)didUpdateDiagnosticForKey:(NSString *)key withValue:(float)value;

@end

@interface BluetoothController : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
	id <BluetoothControllerDelegate> delegate;
}

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *OBDAdapter;
@property (strong, nonatomic) NSArray *OBDServices;
@property (strong, nonatomic) NSString *connected;
@property (strong, nonatomic) NSMutableDictionary *diagnostics;
@property (retain) id delegate;


-(id)init;
-(void)reconnectPeripheral:(CBPeripheral *) peripheral;
-(void)scanForOBDPeripheral;
-(void)disconnect;

@end
