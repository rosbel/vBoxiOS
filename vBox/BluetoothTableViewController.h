//
//  BluetoothTableViewController.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/19/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEManager.h"

@interface BluetoothTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, BLEManagerDelegate>

@property (nonatomic, strong) NSMutableDictionary *diagnostics;
@property (strong, nonatomic) BLEManager *bluetoothController;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *startBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseBarButton;

- (IBAction)startButtonPressed:(id)sender;
- (IBAction)pauseBarButtonPressed:(id)sender;

@end
