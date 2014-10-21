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
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	UIBarButtonItem *navBarButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
	[self navigationItem].rightBarButtonItem = navBarButton;
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
	if(self.bluetoothController.OBDAdapter)
	{
		[self.bluetoothController.centralManager cancelPeripheralConnection:self.bluetoothController.OBDAdapter];
	}
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
	NSString *key = (NSString *)[keys objectAtIndex:indexPath.row];
	NSMutableArray *values = (NSMutableArray *)[self.diagnostics objectForKey:key];
	NSArray *timeStampedValue = (NSArray *)[values lastObject];
	NSNumber *value = (NSNumber *)timeStampedValue[1];
	
	NSString *text = [NSString stringWithFormat:@"%@ - %@ count:%lu",key,value,(unsigned long)[values count]];
	
	cell.textLabel.text = text;
	
	return cell;
}

#pragma mark Bluetooth Delegate Methods

-(void)didUpdateDiagnosticForKey:(NSString *)key withValue:(float)value
{
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

-(void)didFindPeripheral
{
	self.navigationItem.title = @"Discovered OBD Adapter";
	[spinner stopAnimating];
}

-(void)bluetoothStateChangedTo:(NSString *)state
{
	self.navigationItem.title = state;
}

#pragma mark Toolbar Button Actions

- (IBAction)startButtonPressed:(id)sender
{
	if(!self.bluetoothController)
	{
		self.bluetoothController = [[BluetoothController alloc] init];
		self.bluetoothController.delegate = self;
		self.diagnostics = self.bluetoothController.diagnostics;
	}else
	{
		if(self.bluetoothController.OBDAdapter)
			[self.bluetoothController reconnectPeripheral:self.bluetoothController.OBDAdapter];
		else
		{
			[self.bluetoothController scanForOBDPeripheral];
		}
	}
	self.startBarButton.enabled = NO;
	self.pauseBarButton.enabled = YES;
}

- (IBAction)pauseBarButtonPressed:(id)sender
{
	[self.bluetoothController disconnect];
	self.startBarButton.enabled = YES;
	self.pauseBarButton.enabled = NO;
}


@end
