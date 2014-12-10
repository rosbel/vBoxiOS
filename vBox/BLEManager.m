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
#define PID_GPS_ALTITUDE 0xC
#define PID_GPS_SPEED 0xF00D
#define PID_GPS_HEADING 0xF00E
#define PID_GPS_SAT_COUNT 0xF00F
#define PID_GPS_TIME 0xF010
#define PID_ACC 0xF020
#define PID_GYRO 0xF021

#pragma mark - Interface
@interface BLEManager() <CBCentralManagerDelegate,CBPeripheralDelegate,CBPeripheralManagerDelegate>

@property (nonatomic, strong, readonly) CBCentralManager *centralManager;
@property (nonatomic, strong, readonly) CBPeripheral *peripheral;
@property (nonatomic, strong, readonly) CBUUID *uid;

@end

#pragma mark - Implementation 

@implementation BLEManager{
	struct BLE_DATA{
		uint32_t time;
		uint16_t pid;
		uint8_t flags;
		uint8_t checksum;
		float value[3];
	};
	CBPeripheralManager *peripheralManager;
	CBMutableCharacteristic *myCharacteristic;
}


#pragma mark - Initialization

-(id) init
{
	self = [super init];
	if(self)
	{
		_connected = NO;
		
		dispatch_queue_t centralManagerQueue = dispatch_queue_create("bluetoothThread",DISPATCH_QUEUE_SERIAL);
		_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralManagerQueue options:@{CBCentralManagerOptionShowPowerAlertKey:@YES}];
		
		BOOL connectToBeagleBone = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldConnectToBeagleBone"];
		if(connectToBeagleBone)
		{
			dispatch_queue_t peripheralManagerQueue = dispatch_queue_create("peripheralThread",DISPATCH_QUEUE_SERIAL);
			peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:peripheralManagerQueue options:@{CBPeripheralManagerOptionShowPowerAlertKey:@NO}];
		}
	}
	return self;
}

#pragma mark - BluetoothManager Methods

//Main Thread
-(BOOL)scanForPeripheralType:(PeripheralType) type
{
	if(self.centralManager.state != CBCentralManagerStatePoweredOn)
	{
		[self asyncDebugLogWithString:@"State != ON"];
		return NO;
	}
	
	switch(type)
	{
		case PeripheralTypeOBDAdapter:
			_uid = [CBUUID UUIDWithString:OBDAdapterServiceUID];
			break;
		case PeripheralTypeBeagleBone:
			_uid = [CBUUID UUIDWithString:BeagleBoneServiceUID];
			break;
	}
	
	[self asyncDebugLogWithString:@"Scanning for peripheral"];
	
	[self.centralManager scanForPeripheralsWithServices:@[self.uid] options:nil];
	
	if([self.delegate respondsToSelector:@selector(didBeginScanningForPeripheral)])
		[self.delegate didBeginScanningForPeripheral];
	return YES;
}

//Main Thread
-(void)stopScanning
{
	[self.centralManager stopScan];
	if([self.delegate respondsToSelector:@selector(didStopScanning)])
		[self.delegate didStopScanning];
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

//Main Thread
-(void)stopAdvertisingPeripheral
{
	if(peripheralManager)
	{
		if([peripheralManager isAdvertising])
			[peripheralManager stopAdvertising];
	}
}

#pragma mark - CBPeripheralManager Delegate Methods

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
	switch(peripheral.state)
	{
		case CBPeripheralManagerStatePoweredOff:
			break;
		case CBPeripheralManagerStatePoweredOn:
		{
			CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"FFEF"] primary:YES];
			myCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"FFE1"] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify | CBCharacteristicPropertyWriteWithoutResponse value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
			service.characteristics = @[myCharacteristic];
			[peripheralManager addService:service];
			[peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey:@"vBox",CBAdvertisementDataIsConnectable:@YES,CBAdvertisementDataServiceUUIDsKey:@[service.UUID]}];
			break;
		}
		case CBPeripheralManagerStateResetting:
			break;
		case CBPeripheralManagerStateUnauthorized:
			break;
		case CBPeripheralManagerStateUnknown:
			break;
		case CBPeripheralManagerStateUnsupported:
			break;
	}
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
//	NSLog(@"HOWDY");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
//	NSLog(@"Read Request");
	request.value = myCharacteristic.value ? myCharacteristic.value : [@"Howdy" dataUsingEncoding:NSUTF8StringEncoding];
	[peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
	for(CBATTRequest *request in requests)
	{
//		NSLog(@"Write request = %@",request.value);
		myCharacteristic.value = request.value;
		[peripheral respondToRequest:request withResult:CBATTErrorSuccess];
	}
}

-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
	if(myCharacteristic.value)
		[peripheral updateValue:myCharacteristic.value forCharacteristic:myCharacteristic onSubscribedCentrals:nil];
}

#pragma mark - CBCentralManager Delegate Methods

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	switch(central.state)
	{
		case CBCentralManagerStatePoweredOff:
			if(central)
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
	[peripheral setDelegate:self];
	[peripheral discoverServices:nil];
	
	_connected = YES;
	
	if([self.delegate respondsToSelector:@selector(didConnectPeripheral)])
		[self asyncToMainThread:^{
			[self.delegate didConnectPeripheral];
		}];
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
	NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
	
	if([localName length] > 0)
	{
		[self.centralManager stopScan];
		
		if([self.delegate respondsToSelector:@selector(didStopScanning)])
			[self.delegate didStopScanning];
		
		_peripheral = peripheral;
		_peripheral.delegate = self;
		
		[self.centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
	}
}

#pragma mark - Peripheral Delegate Methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
	[self asyncDebugLogWithString:[NSString stringWithFormat:@"Service count = %lu",(unsigned long)peripheral.services.count]];
	
	for(CBService *service in peripheral.services)
	{
		if([self.delegate respondsToSelector:@selector(didUpdateDebugLogWithString:)])
			[self asyncToMainThread:^{
				[self.delegate didUpdateDebugLogWithString:[NSString stringWithFormat:@"Service UUID = %@",service.UUID]];
			}];
		[peripheral discoverCharacteristics:nil forService:service];
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
	[self asyncDebugLogWithString:[NSString stringWithFormat:@"Characteristic count = %lu",(unsigned long)service.characteristics.count]];
	
	for(CBCharacteristic *characteristic in service.characteristics)
	{
		[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		
		[self asyncDebugLogWithString:[NSString stringWithFormat:@"Characteristic UUID = %@",characteristic.UUID]];
	}
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	struct BLE_DATA receivedData;
	
	[characteristic.value getBytes:&receivedData length:12];
	
	//check for bad CheckSum
	if([self getCheckSum:(char *)&receivedData length:12] != 0)
	{
		return;
	}
	
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
			if(value >= 0)
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
			[self asyncUpdateDiagnosticForKey:@"Ambient Temp" withValue:value ifUnderLimit:1000.0];
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
			//ignore
			break;
		case PID_GPS_LATITUDE:
			//ignore
			break;
		case PID_GPS_LONGITUDE:
			//ignore
			break;
		case PID_GPS_HEADING:
			//ignore
			break;
		case PID_GPS_SAT_COUNT:
			//ignore
			break;
		case PID_GPS_SPEED:
			//ignore
			break;
		case PID_GPS_TIME:
			//ignore
			break;
		case PID_ACC:
			//ignore
			break;
		case 0:
			//ignore
			break;
		case 1:
			//ignore
			break;
		default:
			[self asyncDebugLogWithString:[NSString stringWithFormat:@"Unkown PID: %x - Val: %f",receivedData.pid,receivedData.value[0]]];
			break;
	}
	if(error)
	{
		[self asyncDebugLogWithString:[NSString stringWithFormat:@"Received Error: %@",error.localizedDescription]];
	}
}


#pragma mark - Async Helper Methods

-(void) asyncDebugLogWithString:(NSString *)string
{
	[self asyncToMainThread:^{
		if([self.delegate respondsToSelector:@selector(didUpdateDebugLogWithString:)])
		{
			[self.delegate didUpdateDebugLogWithString:string];
		}
	}];
}

-(void) asyncUpdateDiagnosticForKey:(NSString *)key withValue:(float) value ifUnderLimit:(float)limit
{
	if(value > limit)//don't do anything if value is above limit
		return;
	
	[self asyncToMainThread:^{
	[self.delegate didUpdateDiagnosticForKey:key withValue:[NSNumber numberWithFloat:value]];
	}];
}

-(void) asyncToMainThread:(void(^)(void)) codeBlock
{
	dispatch_async(dispatch_get_main_queue(), codeBlock);
}

#pragma mark - CheckSum For Correct Bluetooth Data

-(uint8_t) getCheckSum:(char *)buffer length:(Byte)len
{
	uint8_t checksum = 0;
	for (Byte i = 0; i < len; i++) {
		checksum ^= buffer[i];
	}
	return checksum;
}



@end
