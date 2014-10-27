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
@property (strong, nonatomic) NSArray *speedDivisions;

@end

@implementation TripDetailViewController{
	GMSCoordinateBounds *bounds;
}

@synthesize  camera;
@synthesize speedDivisions;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.speedColors = @[[UIColor redColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor greenColor]];

	self.speedDivisions = [self calculateSpeedBoundaries];
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
	
	NSMutableArray *spanStyles = [NSMutableArray array];
	
	double segments = 1;
	UIColor *color = nil;
	UIColor *newColor = nil;
	for(GPSLocation *gpsLoc in self.trip.gpsLocations)
	{
		[path addLatitude:[gpsLoc.latitude doubleValue] longitude:[gpsLoc.longitude doubleValue]];
		
		for(NSNumber *bound in self.speedDivisions)
		{
			if(gpsLoc.speed.doubleValue <= bound.doubleValue)
			{
				newColor = [self.speedColors objectAtIndex:[self.speedDivisions indexOfObject:bound]];
				if([newColor isEqual:color])
				{
					segments++;
				}else
				{
//					GMSStrokeStyle *style = [GMSStrokeStyle gradientFromColor:color toColor:newColor];
//					[spanStyles addObject:[GMSStyleSpan spanWithStyle:style segments:segments]];
					[spanStyles addObject:[GMSStyleSpan spanWithColor:color segments:segments]];
					segments = 1;
				}
				color = newColor;
				
				break;
			}
		}
	}
	
	GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
	polyline.strokeWidth = 5;
	polyline.spans = spanStyles;
	polyline.geodesic = YES;
	polyline.map = self.mapView;
	
	bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
	camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(30, 150, 30, 150)];
	
	[self.mapView setCamera:camera];
	self.mapView.settings.compassButton = YES;
	self.mapView.settings.myLocationButton = YES;
	self.mapView.myLocationEnabled = NO;
	[self.mapView setDelegate:self];
}

#pragma mark - Google MapView Delegate Methods

-(BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView
{
	GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds];
	[_mapView animateWithCameraUpdate:update];
	return YES;
}

/*
 // Find the points to divide the line by color
 var color_division = [];
 for (i = 0; i < colors.length - 1; i++) {
 color_division[i] = min + (i + 1) * (max - min) / colors.length;
 }
 color_division[color_division.length] = max;
*/

#pragma mark - Helper Methods


-(NSArray *)calculateSpeedBoundaries
{
	double max = self.trip.maxSpeed.doubleValue;
	NSMutableArray *colorDivision = [NSMutableArray array];
	for(int i = 0; i < self.speedColors.count-1; i++)
	{
		double bound = (i+1) * max / self.speedColors.count;
		[colorDivision addObject:[NSNumber numberWithDouble:bound]];
	}
	[colorDivision addObject:self.trip.maxSpeed];
	return colorDivision;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

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
