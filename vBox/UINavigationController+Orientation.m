//
//  UINavigationController+Orientation.m
//  vBox
//
//  Created by Rosbel Sanroman on 12/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "UINavigationController+Orientation.h"

@implementation UINavigationController (Orientation)

-(NSUInteger)supportedInterfaceOrientations
{
	return [self.topViewController supportedInterfaceOrientations];
}

-(BOOL)shouldAutorotate
{
	return [self.topViewController shouldAutorotate];
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return [[self topViewController] preferredInterfaceOrientationForPresentation];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
