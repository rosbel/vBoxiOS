//
//  BluetoothManager.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/31/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "BLEManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

#pragma mark - PIDs

#define PID_SPEED 0x10D
#define PID_FUEL_LEVEL 0x12F
#define PID_COOLANT_TEMP 0x105
#define PID_ENGINE_LOAD 0x104
#define PID_RPM 0x10C
#define PID_THROTTLE 0x111
#define PID_RUNTIME 0x11F
#define PID_DISTANCE 0x131
#define PID_ENGINE_FUEL_RATE 0x159
#define PID_ENGINE_TORQUE_PERCENTAGE 0x15B
#define PID_BAROMETRIC 0x133
#define PID_AMBIENT_TEMP 0x146
#define PID_INTAKE_TEMP 0x10F
#define PID_GPS_LATITUDE 0xF00A
#define PID_GPS_LONGITUDE 0xF00B
#define PID_GPS_ALTITUDE 0xF00C
#define PID_GPS_SPEED 0xF00D
#define PID_GPS_HEADING 0xF00E
#define PID_GPS_SAT_COUNT 0xF00F
#define PID_GPS_TIME 0xF010
#define PID_ACC 0xF020
#define PID_GYRO 0xF021

@interface BLEManager() <CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong, readonly) CBCentralManager *centralManager;
@property (nonatomic, strong, readonly) CBPeripheral *peripheral;

@end

@implementation BLEManager{
	struct BLE_DATA{
		uint32_t time;
		uint16_t pid;
		uint8_t flags;
		uint8_t checksum;
		float value[3];
	};
	
	CBUUID *uid;
	dispatch_queue_t centralManagerQueue;
}


#pragma mark - Initialization

-(id) init
{
	self = [super init];
	if(self)
	{
		centralManagerQueue = dispatch_queue_create("bluetoothThread",DISPATCH_QUEUE_SERIAL);
		_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralManagerQueue];
		_connected = NO;
	}
	return self;
}

#pragma mark - BluetoothManager Methods

//Main Thread
-(BOOL)scanForPeripheralType:(PeripheralType) type
{
	if(self.centralManager.state != CBCentralManagerStatePoweredOn)
	{
		[self.delegate didUpdateDebugLogWithString:@"State was not Powered ON"];
		return NO;
	}
	switch(type)
	{
		case PeripheralTypeOBDAdapter:
			uid = [CBUUID UUIDWithString:OBDAdapterServiceUID];
			break;
		case PeripheralTypeBeagleBone:
			uid = [CBUUID UUIDWithString:BeagleBoneServiceUID];
			break;
	}
	[self.delegate didUpdateDebugLogWithString:@"Scanning for peripheral"];
	[self.centralManager scanForPeripheralsWithServices:@[uid] options:nil];
	if([self.delegate respondsToSelector:@selector(didBeginScanningForPeripheral)])
		[self.delegate didBeginScanningForPeripheral];
	return YES;
}

//Main Thread
-(void)disconnect
{
	if(self.peripheral)
	{
		if(self.peripheral.state == CBPeripheralStateConnected)
			[self.centralManager cancelPeripheralConnection:self.peripheral];
	}
}

//Main Thread
-(void)setNotifyValue:(BOOL)value
{
	if(self.peripheral)
	{
		if(self.peripheral.state == CBPeripheralStateConnected)
		{
			CBCharacteristic *characteristic = [((CBService *)[self.peripheral.services objectAtIndex:0]).characteristics objectAtIndex:0];
			[self.peripheral setNotifyValue:value forCharacteristic:characteristic];
		}
	}
}

#pragma mark - CBCentralManager Delegate Methods

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	switch(central.state)
	{
		case CBCentralManagerStatePoweredOff:
			self.state =  BLEStateOff;
			break;
		case CBCentralManagerStatePoweredOn:
			self.state = BLEStateOn;
			break;
		case CBCentralManagerStateResetting:
			self.state = BLEStateResetting;
			break;
		case CBCentralManagerStateUnauthorized:
			self.state = BLEStateUnauthorized;
			break;
		case CBCentralManagerStateUnknown:
			self.state = BLEStateUnkown;
			break;
		case CBCentralManagerStateUnsupported:
			self.state = BLEStateUnsupported;
			break;
	}
	[self asyncToMainThread:^{
		[self.delegate didChangeBluetoothState:self.state];
	}];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	[self.peripheral discoverServices:nil]; //Discover all services
	if([self.delegate respondsToSelector:@selector(didConnectPeripheral)])
		[self asyncToMainThread:^{
			[self.delegate didConnectPeripheral];
		}];
	_connected = YES;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	_connected = NO;
	if([self.delegate respondsToSelector:@selector(didDisconnectPeripheral)])
	   [self asyncToMainThread:^{
		   [self.delegate didDisconnectPeripheral];
	   }];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	[self asyncToMainThread:^{
		[self.delegate didUpdateDebugLogWithString:@"Discovered Peripheral"];
	}];
	NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
	
	if([localName length] > 0)
	{
		[self.centralManager stopScan];
		
		_peripheral = peripheral;
		_peripheral.delegate = self;
		
		[self.centralManager connectPeripheral:_peripheral options:nil];
	}
}

#pragma mark - Peripheral Delegate Methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
	[self asyncToMainThread:^{
		[self.delegate didUpdateDebugLogWithString:[NSString stringWithFormat:@"Service count = %lu",(unsigned long)peripheral.services.count]];
	}];
	
	for(CBService *service in peripheral.services)
	{
		[self asyncToMainThread:^{
			[self.delegate didUpdateDebugLogWithString:[NSString stringWithFormat:@"Service UUID = %@",service.UUID]];
		}];
		[peripheral discoverCharacteristics:nil forService:service];
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
	[self asyncToMainThread:^{
		[self.delegate didUpdateDebugLogWithString:[NSString stringWithFormat:@"Characteristic count = %lu",(unsigned long)service.characteristics.count]];
	}];
	
	for(CBCharacteristic *characteristic in service.characteristics)
	{
		[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		[self asyncToMainThread:^{
			[self.delegate didUpdateDebugLogWithString:[NSString stringWithFormat:@"Characteristic UUID = %@",characteristic.UUID]];
		}];
	}
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	struct BLE_DATA receivedData;
	
	[characteristic.value getBytes:&receivedData length:20];
	float value;
	switch(receivedData.pid)
	{
		case PID_FUEL_LEVEL:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Fuel" withValue:value ifUnderLimit:150.0];
			break;
		case PID_RPM:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"RPM" withValue:value ifUnderLimit:100000.0];
			break;
		case PID_RUNTIME:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Runtime" withValue:value ifUnderLimit:FLT_MAX]; //maybe change
			break;
		case PID_ENGINE_TORQUE_PERCENTAGE:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Engine Torque Percentage" withValue:value ifUnderLimit:150]; //check
			break;
		case PID_ENGINE_LOAD:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Engine Load" withValue:value ifUnderLimit:150]; //check
			break;
		case PID_DISTANCE:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Distance" withValue:value ifUnderLimit:10000000.0]; //check
			break;
		case PID_COOLANT_TEMP:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Coolant Temp" withValue:value ifUnderLimit:500.0];
			break;
		case PID_BAROMETRIC:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Barometric" withValue:value ifUnderLimit:500.0];
			break;
		case PID_SPEED:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Speed" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_ENGINE_FUEL_RATE:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Engine Fuel Rate" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_AMBIENT_TEMP:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Ambien Temp" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_THROTTLE:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Throttle" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_INTAKE_TEMP:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"Intake Temp" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_GPS_ALTITUDE:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"GPS Alt" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_LATITUDE:
			value = receivedData.value[0];
			value /= 100; //offset of 100
			[self asyncUpdateDiagnosticForKey:@"GPS Lat" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_LONGITUDE:
			value = receivedData.value[0];
			value /= 100;
			[self asyncUpdateDiagnosticForKey:@"GPS Long" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_HEADING:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"GPS Heading" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_SAT_COUNT:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"GPS Sat Count" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_SPEED:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"GPS Speed" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_GPS_TIME:
			value = receivedData.value[0];
			[self asyncUpdateDiagnosticForKey:@"GPS Time" withValue:value ifUnderLimit:1000000.0];
			break;
		case PID_ACC:
			[self asyncUpdateDiagnosticForKey:@"Accelerometer" withMultipleValues:receivedData.value]; //ALL 3 values are needed
			break;
		case 0:
			//ignore
			break;
		case 1:
			//ignore
			break;
		default:
			if([self.delegate respondsToSelector:@selector(didUpdateDebugLogWithString:)])
				[self asyncToMainThread:^{
					[self.delegate didUpdateDebugLogWithString:[NSString stringWithFormat:@"Unkown PID: %x - Val: %f",receivedData.pid,receivedData.value[0]]];
				}];
			break;
	}
	if(error)
	{
		if([self.delegate respondsToSelector:@selector(didUpdateDebugLogWithString:)])
			[self asyncToMainThread:^{
				[self.delegate didUpdateDebugLogWithString:[NSString stringWithFormat:@"Received error: %@",error]];
			}];
	}
}


#pragma mark - Async Helper Methods

-(void) asyncUpdateDiagnosticForKey:(NSString *)key withValue:(float) value ifUnderLimit:(float)limit
{
	if(value > limit)//don't do anything if value is above limit
		return;
	
	[self asyncToMainThread:^{
		[self.delegate didUpdateDiagnosticForKey:key withValue:value];
	}];
}

-(void) asyncUpdateDiagnosticForKey:(NSString *)key withMultipleValues:(float[])values
{
	[self asyncToMainThread:^{
		[self.delegate didUpdateDiagnosticForKey:key withMultipleValues:values];
	}];
}

-(void) asyncToMainThread:(void(^)(void)) codeBlock
{
	dispatch_async(dispatch_get_main_queue(), codeBlock);
}



@end