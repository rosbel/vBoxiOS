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
	
	NSArray *keys = [self.diagnostics allKeys];
	NSString *key = [keys objectAtIndex:indexPath.row];
	NSString *text = [key stringByAppendingString:@" - "];
	if([key isEqualToString:@"Accelerometer"])
	{
		NSNumber *value = [keys valueForKey:key];
		[text stringByAppendingString:value.description];
	}
	else
	{
		NSArray *values = [keys valueForKey:key];
		[text stringByAppendingString:values.description];
	}
	
	cell.textLabel.text = text;
	
	return cell;
}

#pragma mark Bluetooth Delegate Methods

-(void)didUpdateDiagnosticForKey:(NSString *)key withValue:(float)value
{
	[self.diagnostics setObject:[NSNumber numberWithFloat:value] forKey:key];
	
	//insert into core data?
	
	[self.tableView reloadData];
}

-(void)didUpdateDiagnosticForKey:(NSString *)key withMultipleValues:(float [])values
{
	NSNumber *x = [NSNumber numberWithFloat:values[0]];
	NSNumber *y = [NSNumber numberWithFloat:values[1]];
	NSNumber *z = [NSNumber numberWithFloat:values[2]];
	[self.diagnostics setObject:@[x,y,z] forKey:key];
	
	//insert into core data?
	
	[self.tableView reloadData];
}

-(void)didStartScanningForPeripheral
{
	[spinner startAnimating];
}

-(void)didDisconnectPeripheral
{
	self.navigationItem.title = @"Disconnected";
	[spinner stopAnimating];
}

-(void)didConnectToPeripheral
{
	self.navigationItem.title = @"Connected";
	[spinner stopAnimating];
}

-(void)didChangeBluetoothState:(BLEState)state
{
	NSString *title;
	switch(state)
	{
		case BLEStateOn:
			title = @"Bluetooth On";
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
}

- (IBAction)pauseBarButtonPressed:(id)sender
{
	[self.bluetoothController setNotifyValue:NO];
}


@end
