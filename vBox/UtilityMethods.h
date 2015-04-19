//
//  UtilityMethods.h
//  vBox
//
//  Created by Rosbel Sanroman on 4/18/15.
//  Copyright (c) 2015 rosbelSanroman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UtilityMethods : NSObject

+(NSString *)durationInStringOfTimeIntervalFrom:(NSDate *)starTime to:(NSDate *)endTime;
+(NSString *)formattedStringFromDate:(NSDate *)date;

@end
