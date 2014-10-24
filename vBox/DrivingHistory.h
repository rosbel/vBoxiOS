//
//  DrivingHistory.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Trip;

@interface DrivingHistory : NSManagedObject

@property (nonatomic, retain) NSOrderedSet *trips;
@end

@interface DrivingHistory (CoreDataGeneratedAccessors)

- (void)insertObject:(Trip *)value inTripsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTripsAtIndex:(NSUInteger)idx;
- (void)insertTrips:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTripsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTripsAtIndex:(NSUInteger)idx withObject:(Trip *)value;
- (void)replaceTripsAtIndexes:(NSIndexSet *)indexes withTrips:(NSArray *)values;
- (void)addTripsObject:(Trip *)value;
- (void)removeTripsObject:(Trip *)value;
- (void)addTrips:(NSOrderedSet *)values;
- (void)removeTrips:(NSOrderedSet *)values;
@end
