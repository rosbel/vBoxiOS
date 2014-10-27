//
//  TripDetailViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "TripDetailViewController.h"

@interface TripDetailViewController ()

@property (nonatomic,strong) GMSCameraPosition *camera;

@end

@implementation TripDetailViewController
{
	
}

@synthesize  camera;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self setUpGoogleMaps];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
	NSLog(@"Memory Warning!");
}

- (void) setUpGoogleMaps
{
	GMSMutablePath *path = [GMSMutablePath path];
	
	for(GPSLocation *gpsLoc in self.trip.gpsLocations)
	{
		[path addLatitude:[gpsLoc.latitude doubleValue] longitude:[gpsLoc.longitude doubleValue]];
	}
	
	GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
	polyline.strokeWidth = 5;
	polyline.strokeColor = [UIColor greenColor];
	polyline.geodesic = YES;
	polyline.map = self.mapView;
	
	GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
	camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(30, 150, 30, 150)];
	
	[self.mapView setCamera:camera];
	self.mapView.settings.compassButton = YES;
	[self.mapView setDelegate:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Helper Methods

-(UIColor *)colorBasedOnMPHSpeed:(int)speed
{
	if(speed >= 85)
	{
		return [UIColor blueColor];
	}
	else if(speed >= 60 && speed < 85)
	{
		return [UIColor greenColor];
	}
	else if(speed >= 40 && speed < 60)
	{
		return [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
	}
	else if(speed >= 30 && speed < 40)
	{
		return [UIColor yellowColor];
	}
	else if(speed >= 20 && speed < 30)
	{
		return [UIColor orangeColor];
	}
	else if(speed >= 1 && speed < 20)
	{
		return [UIColor redColor];
	}
	else
	{
		return [UIColor blackColor];
	}
}

#pragma mark - PNChart Delegates
/**
 * When user click on the chart line
 *
 */
- (void)userClickedOnLinePoint:(CGPoint)point lineIndex:(NSInteger)lineIndex
{
	
}

/**
 * When user click on the chart line key point
 *
 */
- (void)userClickedOnLineKeyPoint:(CGPoint)point lineIndex:(NSInteger)lineIndex andPointIndex:(NSInteger)pointIndex
{
	
}

/**
 * When user click on a chart bar
 *
 */
- (void)userClickedOnBarCharIndex:(NSInteger)barIndex
{
	
}

@end
