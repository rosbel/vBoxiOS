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
@property (strong, nonatomic) NSOrderedSet *GPSLocationsForTrip;
@property (strong, nonatomic) GMSMutablePath *pathForTrip;
@end

@implementation TripDetailViewController{
	GMSCoordinateBounds *bounds;
}

@synthesize pathForTrip;
@synthesize GPSLocationsForTrip;
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
	GPSLocationsForTrip = self.trip.gpsLocations;
	
	pathForTrip = [GMSMutablePath path];
	
	NSMutableArray *spanStyles = [NSMutableArray array];
	double segments = 1;
	UIColor *color = nil;
	UIColor *newColor = nil;
	
	for(GPSLocation *gpsLoc in GPSLocationsForTrip)
	{
		[pathForTrip addLatitude:[gpsLoc.latitude doubleValue] longitude:[gpsLoc.longitude doubleValue]];
		
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
					[spanStyles addObject:[GMSStyleSpan spanWithColor:color?color:newColor segments:segments]];
					segments = 1;
				}
				color = newColor;
				
				break;
			}
		}
	}
	
	GMSPolyline *polyline = [GMSPolyline polylineWithPath:pathForTrip];
	polyline.strokeWidth = 5;
	polyline.spans = spanStyles;
	polyline.geodesic = YES;
	polyline.map = self.mapView;
	
	bounds = [[GMSCoordinateBounds alloc] initWithPath:pathForTrip];
	camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(30, 150, 30, 150)];
	
	[self.mapView setCamera:camera];
	self.mapView.settings.compassButton = YES;
	self.mapView.myLocationEnabled = NO;
	[self.mapView setDelegate:self];
}

#pragma mark - Helper Methods

-(void)insertMarkerInMap:(GMSMapView *)myMapView withGPSLocation:(GPSLocation *)gpsLoc
{
	GMSMarker *marker = [[GMSMarker alloc]init];
	marker.position = CLLocationCoordinate2DMake(gpsLoc.latitude.doubleValue, gpsLoc.longitude.doubleValue);
	marker.appearAnimation = kGMSMarkerAnimationPop;
	marker.map = myMapView;
	marker.snippet = [NSString stringWithFormat:@"Time: %@\nSpeed: %.2f",gpsLoc.timestamp,gpsLoc.speed.doubleValue];
}

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
#pragma mark - Google MapView Delegate Methods

-(void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
	//Proceed only if Tap is in path
	NSLog(@"%f",mapView.camera.zoom);
	if(!GMSGeometryIsLocationOnPath(coordinate, pathForTrip, NO,1000.0))
		return;
	
	NSLog(@"SUCCESS");
	NSLog(@"Count = %lu",(unsigned long)pathForTrip.count);
	
	GPSLocation *closestLocation = nil;
	CLLocationDistance closestDistance = CLLocationDistanceMax;
	
	for(GPSLocation *location in GPSLocationsForTrip)
	{
		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(location.latitude.doubleValue, location.longitude.doubleValue);
		CLLocationDistance distance = GMSGeometryDistance(coord, coordinate);
		if(distance < closestDistance)
		{
			closestDistance = distance;
			closestLocation = location;
		}
	}
	if(closestLocation)
		[self insertMarkerInMap:mapView withGPSLocation:closestLocation];
	NSLog(@"Closest location = (%@,%@) - speed = %@ (%@) mph",closestLocation.latitude,closestLocation.longitude,closestLocation.speed,closestLocation.timestamp);
}

@end
