//
//  GPSLocation.h
//  vBox
//
//  Created by Rosbel Sanroman on 11/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BluetoothData, Trip;

@interface GPSLocation : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Trip *tripInfo;
@property (nonatomic, retain) BluetoothData *bluetoothInfo;

@end
