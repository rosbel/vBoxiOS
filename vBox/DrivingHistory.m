//
//  DrivingHistory.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "DrivingHistory.h"
#import "Trip.h"


@implementation DrivingHistory

@dynamic trips;

- (void)addTripsObject:(Trip *)value
{
	NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.trips];
	[tempSet addObject:value];
	self.trips = tempSet;
}

@end
