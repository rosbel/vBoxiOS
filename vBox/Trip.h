//
//  Trip.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/27/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DrivingHistory, GPSLocation;

@interface Trip : NSManagedObject

@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * avgSpeed;
@property (nonatomic, retain) NSNumber * maxSpeed;
@property (nonatomic, retain) DrivingHistory *drivingHistory;
@property (nonatomic, retain) NSOrderedSet *gpsLocations;
@end

@interface Trip (CoreDataGeneratedAccessors)

- (void)insertObject:(GPSLocation *)value inGpsLocationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGpsLocationsAtIndex:(NSUInteger)idx;
- (void)insertGpsLocations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGpsLocationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGpsLocationsAtIndex:(NSUInteger)idx withObject:(GPSLocation *)value;
- (void)replaceGpsLocationsAtIndexes:(NSIndexSet *)indexes withGpsLocations:(NSArray *)values;
- (void)addGpsLocationsObject:(GPSLocation *)value;
- (void)removeGpsLocationsObject:(GPSLocation *)value;
- (void)addGpsLocations:(NSOrderedSet *)values;
- (void)removeGpsLocations:(NSOrderedSet *)values;
@end
