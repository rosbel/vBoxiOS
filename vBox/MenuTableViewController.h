//
//  MenuTableTableViewController.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/15/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothController.h"

@interface MenuTableViewController : UITableViewController

@property (strong,nonatomic)UIViewController *googleViewController;
@property (strong,nonatomic)BluetoothController *bluetoothController;

@end
