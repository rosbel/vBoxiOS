//
//  BluetoothCentral.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/16/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "BluetoothController.h"

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

@interface BluetoothController()

@end

@implementation BluetoothController{
	struct BLE_DATA{
		uint32_t time;
		uint16_t pid;
		uint8_t flags;
		uint8_t checksum;
		float value[3];
	};
}

@synthesize delegate;

-(id)init
{
	self = [super init];
	if(self)
	{
		self.diagnostics = [[NSMutableDictionary alloc] init];
		CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
		self.centralManager = centralManager;
		
		self.OBDServices = @[[CBUUID UUIDWithString:@"FFE0"]];
	}
	return self;
}

#pragma mark Helper Methods
-(void)scanForOBDPeripheral
{
	[self.centralManager scanForPeripheralsWithServices:self.OBDServices options:nil];
	[self notifyDelegateBluetoothStatusChangedTo:@"Scanning.."];
}

-(void)reconnectPeripheral:(CBPeripheral *)peripheral
{
	if(self.centralManager)
	{
		if(peripheral)
		{
			[self.centralManager connectPeripheral:peripheral options:nil];
		}else
		{
			[self scanForOBDPeripheral];
		}
	}else
	{
		//Should not happen throw error
	}
}

-(void)disconnect
{
	if(self.OBDAdapter)
	{
		if(self.OBDAdapter)
			[self.centralManager cancelPeripheralConnection:self.OBDAdapter];
	}
	if([self.delegate respondsToSelector:@selector(didDisconnectPeripheral)])
		[self.delegate didDisconnectPeripheral];
}

#pragma mark - CBManager Delegate Methods

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	[peripheral setDelegate:self];
	[peripheral discoverServices:nil];
	
	self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
	NSLog(@"%@", self.connected);
	if([self.delegate respondsToSelector:@selector(didConnectToPeripheral)])
	{
		[self.delegate didConnectToPeripheral];
	}
	
	[self notifyDelegateBluetoothStatusChangedTo:@"Connected OBD"];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	if([self.delegate respondsToSelector:@selector(didDisconnectPeripheral)])
	{
		[self.delegate didDisconnectPeripheral];
	}
	
	[self notifyDelegateBluetoothStatusChangedTo:@"Disconnected OBD"];
	
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
	if([localName length] > 0)
	{
		[self.centralManager stopScan];
		
		self.OBDAdapter = peripheral;
		peripheral.delegate = self;
		[self.centralManager connectPeripheral:peripheral options:nil];
	}
	if([self.delegate respondsToSelector:@selector(didFindPeripheral)])
	{
		[self.delegate didFindPeripheral];
	}
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	//~~~~~~~~~~~~~~~~~~POWERED OFF~~~~~~~~~~~~~~~~~~
	if([central state] == CBCentralManagerStatePoweredOff){
		[self notifyDelegateWithLog:@"CB BLE state is powered off"];
		
		[self notifyDelegateBluetoothStatusChangedTo:@"Bluetooth is OFF"];
		
	}
	//~~~~~~~~~~~~~~~~~~POWERED ON~~~~~~~~~~~~~~~~~~
	else if([central state] == CBCentralManagerStatePoweredOn){
		[self notifyDelegateWithLog:@"BLE state is turned on"];
		
		[self notifyDelegateBluetoothStatusChangedTo:@"Bluetooth is ON"];
		
		[self scanForOBDPeripheral]; //SCAN FOR OBD
		
		[self notifyDelegateBluetoothStatusChangedTo:@"Scanning.."];
	}
	//~~~~~~~~~~~~~~~~~~UNAUTHORIZED~~~~~~~~~~~~~~~~~~
	else if([central state] == CBCentralManagerStateUnauthorized){
		[self notifyDelegateWithLog:@"CB BLE state is unauthorized"];
		
		[self notifyDelegateBluetoothStatusChangedTo:@"Bluetooth is Unauthorized"];
	}
	//~~~~~~~~~~~~~~~~~~UNKOWN~~~~~~~~~~~~~~~~~~
	else if([central state] == CBCentralManagerStateUnknown){
		[self notifyDelegateWithLog:@"CB BLE state unknown"];
		
		[self notifyDelegateBluetoothStatusChangedTo:@"Bluetooth is Unkown"];
	}
	//~~~~~~~~~~~~~~~~~~UNSUPORTED~~~~~~~~~~~~~~~~~~
	else if([central state] == CBCentralManagerStateUnsupported){
		[self notifyDelegateWithLog:@"CoreBluetooth BLE state is unsupported"];
		
		[self notifyDelegateBluetoothStatusChangedTo:@"Bluetooth is Unsupported"];
	}
	
}

#pragma mark - CBPeripheral Delegate Methods

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
	for (CBService *service in peripheral.services)
	{
		[self notifyDelegateWithLog:[NSString stringWithFormat:@"Discovered service: %@",service.UUID]];
		[peripheral discoverCharacteristics:nil forService:service];
	}
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
	for(CBCharacteristic *characteristic in service.characteristics)
	{
		[self notifyDelegateWithLog:[NSString stringWithFormat:@"Found Characteristic: %@",characteristic.UUID]];
		
		[peripheral setNotifyValue:YES forCharacteristic:characteristic]; //maybe wait for click?
		[self.OBDAdapter readValueForCharacteristic:characteristic]; //check this
	}
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	for(CBDescriptor *descriptor in characteristic.descriptors)
	{
		[self notifyDelegateWithLog:[NSString stringWithFormat:@"Descriptor: %@",descriptor]];
	}
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	struct BLE_DATA myData12;
	struct BLE_DATA receivedData;
	
	[characteristic.value getBytes:&myData12 length:12];
	[characteristic.value getBytes:&receivedData length:20];
	float value;
	switch(receivedData.pid)
	{
		case PID_FUEL_LEVEL:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Fuel" withValue:value ifUnderLimit:150.0];
			break;
		case PID_RPM:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"RPM" withValue:value ifUnderLimit:100000.0];
			break;
		case PID_RUNTIME:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Runtime" withValue:value ifUnderLimit:FLT_MAX]; //maybe change
			break;
		case PID_ENGINE_TORQUE_PERCENTAGE:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Engine Torque Percentage" withValue:value ifUnderLimit:150]; //check
			break;
		case PID_ENGINE_LOAD:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Engine Load" withValue:value ifUnderLimit:150]; //check
			break;
		case PID_DISTANCE:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Distance" withValue:value ifUnderLimit:10000000.0]; //check
			break;
		case PID_COOLANT_TEMP:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Coolant Temp" withValue:value ifUnderLimit:500.0];
			break;
		case PID_BAROMETRIC:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Barometric" withValue:value ifUnderLimit:500.0];
			break;
		case PID_SPEED:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Speed" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_ENGINE_FUEL_RATE:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Engine Fuel Rate" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_AMBIENT_TEMP:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Ambien Temp" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_THROTTLE:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Throttle" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_INTAKE_TEMP:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"Intake Temp" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_GPS_ALTITUDE:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"GPS Alt" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_LATITUDE:
			value = receivedData.value[0];
			value /= 100; //offset of 100
			[self insertDiagnosticForKey:@"GPS Lat" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_LONGITUDE:
			value = receivedData.value[0];
			value /= 100;
			[self insertDiagnosticForKey:@"GPS Long" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_HEADING:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"GPS Heading" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_SAT_COUNT:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"GPS Sat Count" withValue:value ifUnderLimit:FLT_MAX];
			break;
		case PID_GPS_SPEED:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"GPS Speed" withValue:value ifUnderLimit:1000.0];
			break;
		case PID_GPS_TIME:
			value = receivedData.value[0];
			[self insertDiagnosticForKey:@"GPS Time" withValue:value ifUnderLimit:1000000.0];
			break;
		case PID_ACC:
			[self insertDiagnosticForKey:@"Accelerometer" withMultipleValues:receivedData.value]; //ALL 3 values are needed
			break;
		case 0:
			//ignore
			break;
		case 1:
			//ignore
			break;
		default:
			[self notifyDelegateWithLog:[NSString stringWithFormat:@"Unkown PID: %x - Val: %f",receivedData.pid,receivedData.value[0]]];
			break;
	}
	if(error)
	{
		[self notifyDelegateWithLog:[NSString stringWithFormat:@"Received error: %@",error]];
	}
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	
}

#pragma mark - Delegate Methods

-(void)notifyDelegateWithLog:(NSString *) log
{
	log = [log stringByAppendingString:@"\n"];
	NSLog(@"%@",log);
	if([self.delegate respondsToSelector:@selector(didUpdateLogWithString:)])
	{
		[[self delegate] didUpdateLogWithString:log];
	}
}


-(void)notifyDelegateBluetoothStatusChangedTo:(NSString *)status
{
	if([self.delegate respondsToSelector:@selector(bluetoothStateChangedTo:)])
		[self.delegate bluetoothStateChangedTo:status];
}

#pragma mark - Insert Objects To Diagnostics

-(void)insertDiagnosticForKey:(NSString *)key withValue:(float)value ifUnderLimit:(float)limit
{
	if(value > limit)//don't do anything if value is above limit
		return;
	NSMutableArray *array = (NSMutableArray *)[self.diagnostics objectForKey:key];
	
	if(!array)
	{
		array = [[NSMutableArray alloc] init];
		[self.diagnostics setObject:array forKey:key];
	}
	
	[array addObject:@[[NSDate date],[NSNumber numberWithFloat:value]]]; //CHECK IF VALID
	
	[[self delegate] didUpdateDiagnosticForKey:key withValue:value];
	
	[self notifyDelegateWithLog:[NSString stringWithFormat:@"%@:%@",key,array]];
	
}

-(void)insertDiagnosticForKey:(NSString *)key withMultipleValues:(float[])values
{
	NSMutableArray *array = (NSMutableArray *)[self.diagnostics objectForKey:key];
	if(!array)
	{
		array = [[NSMutableArray alloc] init];
		[self.diagnostics setObject:array forKey:key];
	}
	NSNumber *val0 = [NSNumber numberWithFloat:values[0]];
	NSNumber *val1 = [NSNumber numberWithFloat:values[1]];
	NSNumber *val2 = [NSNumber numberWithFloat:values[2]];
	[array addObject:[NSArray arrayWithObjects:val0,val1,val2, nil]];
	
	[self notifyDelegateWithLog:[NSString stringWithFormat:@"%@:(%@,%@,%@)",key,val0,val1,val2]];
	
}


@end
