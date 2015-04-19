//
//  UtilityMethods.m
//  vBox
//
//  Created by Rosbel Sanroman on 4/18/15.
//  Copyright (c) 2015 rosbelSanroman. All rights reserved.
//

#import "UtilityMethods.h"

@implementation UtilityMethods

+(NSString *)durationInStringOfTimeIntervalFrom:(NSDate *)starTime to:(NSDate *)endTime
{
    NSTimeInterval timeSinceStart = [endTime timeIntervalSinceDate:starTime];
    NSInteger ti = (NSInteger)timeSinceStart;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02li:%02li:%02li",(long)hours,(long)minutes,(long)seconds];
}

+(NSString *)formattedStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM dd, yyy (EEEE) HH:mm:ss z Z"];
    return [dateFormatter stringFromDate:date];
}

@end
