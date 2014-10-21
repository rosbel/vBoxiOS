//
//  CarDiagnostics.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/18/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "CarDiagnostics.h"

@implementation CarDiagnostics
{
	
}

-(id)init
{
	self = [super init];
	if(self)
	{
		self.diagnostics = [[NSMutableDictionary alloc] init];
	}
	return self;
}

@end
