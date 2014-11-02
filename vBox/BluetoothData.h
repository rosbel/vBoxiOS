//
//  BluetoothData.h
//  vBox
//
//  Created by Rosbel Sanroman on 11/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GPSLocation;

@interface BluetoothData : NSManagedObject

@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) NSNumber * ambientTemp;
@property (nonatomic, retain) NSNumber * fuel;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSNumber * barometric;
@property (nonatomic, retain) NSNumber * rpm;
@property (nonatomic, retain) NSNumber * coolantTemp;
@property (nonatomic, retain) NSNumber * engineLoad;
@property (nonatomic, retain) NSNumber * intakeTemp;
@property (nonatomic, retain) NSNumber * throttle;
@property (nonatomic, retain) NSNumber * accelX;
@property (nonatomic, retain) NSNumber * accelY;
@property (nonatomic, retain) NSNumber * accelZ;
@property (nonatomic, retain) GPSLocation *location;

@end
