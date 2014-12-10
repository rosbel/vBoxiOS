//
//  BluetoothTableViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/19/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "BluetoothTableViewController.h"

@interface BluetoothTableViewController ()

@end

@implementation BluetoothTableViewController{
	UIActivityIndicatorView *spinner;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.pauseBarButton.enabled = NO;
	self.diagnostics = [NSMutableDictionary dictionary];
	self.bluetoothController = [[BLEManager alloc] init];
	self.bluetoothController.delegate = self;
	
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	UIBarButtonItem *navBarButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
	self.navigationItem.rightBarButtonItem = navBarButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)viewWillDisappear:(BOOL)animated
{
	[self.bluetoothController disconnect];
}


#pragma mark Table View Delegate Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.diagnostics count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *simpleTableIdentifier = @"SimpleTableCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
	
	if (!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
	}
	
	NSArray *keys = [[self.diagnostics allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSString *key = [keys objectAtIndex:indexPath.row];
	NSString *text = [key stringByAppendingString:@" - "];
	if(![key isEqualToString:@"Accelerometer"])
	{
		NSNumber *value = [self.diagnostics objectForKey:key];
		text = [text stringByAppendingString:[NSString stringWithFormat:@"%@",value]];
	}
	else
	{
		NSArray *values = [self.diagnostics objectForKey:key];
		text = [text stringByAppendingString:[NSString stringWithFormat:@"(%@,%@,%@)",[values objectAtIndex:0],[values objectAtIndex:1],[values objectAtIndex:2]]];
	}
	
	cell.textLabel.text = text;
	
	return cell;
}

#pragma mark Bluetooth Delegate Methods

//Bluetooth Thread
-(void)didUpdateDiagnosticForKey:(NSString *)key withValue:(NSNumber *)value
{
	[self.diagnostics setObject:value forKey:key];
	
	//insert into core data?
	[self.tableView reloadData];
//	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

//BluetoothThread
-(void)didUpdateDiagnosticForKey:(NSString *)key withMultipleValues:(NSArray *)values
{
	[self.diagnostics setObject:values forKey:key];
	
	//insert into core data?
	[self.tableView reloadData];
//	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

-(void)didUpdateDebugLogWithString:(NSString *)string
{
	
}

-(void)didBeginScanningForPeripheral
{
	[spinner startAnimating];
	self.navigationItem.title = @"Scanning..";
}

-(void)didStopScanning
{
	[spinner stopAnimating];
	self.navigationItem.title = self.bluetoothController.connected ? @"Connected" : @"Not Connected";
}

-(void)didConnectPeripheral
{
	[spinner stopAnimating];
	self.navigationItem.title = @"Connected";
}

-(void)didDisconnectPeripheral
{
	[spinner stopAnimating];
	self.navigationItem.title = @"Disconnected";
	self.pauseBarButton.enabled = NO;
	self.startBarButton.enabled = YES;
}

-(void)didChangeBluetoothState:(BLEState)state
{
	NSString *title;
	
	if(state != BLEStateOn)
	{
		self.startBarButton.enabled = NO;
		self.pauseBarButton.enabled = NO;
	}
	
	switch(state)
	{
		case BLEStateOn:
			title = @"Bluetooth On";
			self.startBarButton.enabled = YES;
			break;
		case BLEStateOff:
			title = @"Bluetooth Off";
			break;
		case BLEStateResetting:
			title = @"Bluetooth Resetting";
			break;
		case BLEStateUnauthorized:
			title = @"Bluetooth Unauthorized";
			break;
		case BLEStateUnkown:
			title = @"Bluetooth Unkown";
			break;
		case BLEStateUnsupported:
			title = @"Bluetooth Unsupported";
			break;
	}
	[spinner stopAnimating];
	self.navigationItem.title = title;
}

#pragma mark Toolbar Button Actions

- (IBAction)startButtonPressed:(id)sender
{
	if(self.bluetoothController.connected)
	{
		[self.bluetoothController setNotifyValue:YES];
	}
	else
	{
		//Enable User to Choose type
		[self.bluetoothController scanForPeripheralType:PeripheralTypeOBDAdapter];
	}
	
	self.startBarButton.enabled = NO;
	self.pauseBarButton.enabled = YES;
}

- (IBAction)pauseBarButtonPressed:(id)sender
{
	if(self.bluetoothController.connected)
	{
		[self.bluetoothController setNotifyValue:NO];
	}
	else
	{
		[self.bluetoothController stopScanning];
	}
	
	self.startBarButton.enabled = YES;
	self.pauseBarButton.enabled = NO;
}


@end
