//
//  DrivingHistoryViewController.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Trip.h"
#import "TripDetailViewController.h"

@interface DrivingHistoryViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) NSOrderedSet *trips;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
