//
//  TripDetailViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "TripDetailViewController.h"

@interface TripDetailViewController ()

//@property (strong, nonatomic) GMSCameraPosition *camera;
@property (strong, nonatomic) NSArray *speedDivisions;
@property (strong, nonatomic) NSOrderedSet *GPSLocationsForTrip;
@property (strong, nonatomic) GMSMutablePath *pathForTrip;
@property (strong, nonatomic) GMSMarker *markerForSlider;
@property (strong, nonatomic) GMSMarker *markerForTap;

@end

@implementation TripDetailViewController{
	GMSCoordinateBounds *cameraBounds;
	GPSLocation *startLocation;
}

@synthesize pathForTrip;
@synthesize GPSLocationsForTrip;
//@synthesize camera;
@synthesize speedDivisions;

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.speedColors = @[[UIColor redColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor greenColor]];
	self.speedDivisions = [self calculateSpeedBoundaries];
	
	startLocation = [self.trip.gpsLocations objectAtIndex:0];
	
	[self setUpGoogleMaps];
	
	[self.tripSlider setMaximumValue:self.trip.gpsLocations.count-1];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:cameraBounds withPadding:40];
	[self.mapView animateWithCameraUpdate:update];
}

- (void) setUpGoogleMaps
{
	GPSLocationsForTrip = self.trip.gpsLocations;
	
	pathForTrip = [GMSMutablePath path];
	
	NSMutableArray *spanStyles = [NSMutableArray array];
	double segments = 1;
	UIColor *color = nil;
	UIColor *newColor = nil;
	
	GPSLocation *start = [GPSLocationsForTrip objectAtIndex:0];
	GPSLocation *end = [GPSLocationsForTrip objectAtIndex:[GPSLocationsForTrip count]-1];
	GMSMarker *startMarker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(start.latitude.doubleValue, start.longitude.doubleValue)];
	GMSMarker *endMarker =[GMSMarker markerWithPosition:CLLocationCoordinate2DMake(end.latitude.doubleValue, end.longitude.doubleValue)];
	
	[startMarker setGroundAnchor:CGPointMake(0.5, 0.5)];
	[endMarker setGroundAnchor:CGPointMake(0.5, 0.5)];
	
	[startMarker setMap:self.mapView];
	[endMarker setMap:self.mapView];
	
	[startMarker setIcon:[UIImage imageNamed:@"startPosition"]];
	[endMarker setIcon:[UIImage imageNamed:@"endPosition"]];
	
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
	
	cameraBounds = [[GMSCoordinateBounds alloc] initWithPath:pathForTrip];
	GMSCameraPosition *camera = [self.mapView cameraForBounds:cameraBounds insets:UIEdgeInsetsZero];
	
	self.mapView.camera = [GMSCameraPosition cameraWithLatitude:start.latitude.doubleValue longitude:start.longitude.doubleValue zoom:camera.zoom>5?camera.zoom-4:camera.zoom bearing:120 viewingAngle:25];
	self.mapView.settings.compassButton = YES;
	self.mapView.myLocationEnabled = NO;
	[self.mapView setDelegate:self];
}

#pragma mark - Helper Methods
-(void)updateMarkerForSliderWithLocation:(GPSLocation *)location
{
	if(!self.markerForSlider)
	{
		self.markerForSlider = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(location.latitude.doubleValue, location.longitude.doubleValue)];
		[self.markerForSlider setIcon:[UIImage imageNamed:@"currentLocation"]];
		[self.markerForSlider setGroundAnchor:CGPointMake(0.5, 0.5)];
		[self.markerForSlider setMap:self.mapView];
	}else
	{
		[CATransaction begin];
		[CATransaction setAnimationDuration:0.01];
		[self.markerForSlider setPosition:CLLocationCoordinate2DMake(location.latitude.doubleValue, location.longitude.doubleValue)];
		[CATransaction commit];
	}
}

-(void)updateTapMarkerInMap:(GMSMapView *)myMapView withGPSLocation:(GPSLocation *)gpsLoc
{
	if(!self.markerForTap)
	{
		self.markerForTap = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(gpsLoc.latitude.doubleValue, gpsLoc.longitude.doubleValue)];
		[self.markerForTap setMap:myMapView];
		[self.markerForTap setAppearAnimation:kGMSMarkerAnimationPop];
	}
	self.markerForTap.position = CLLocationCoordinate2DMake(gpsLoc.latitude.doubleValue, gpsLoc.longitude.doubleValue);
	self.markerForTap.snippet = [NSString stringWithFormat:@"Time: %@\nSpeed: %.2f",gpsLoc.timestamp,gpsLoc.speed.doubleValue];
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

#pragma mark - Slider Event

- (IBAction)sliderValueChanged:(UISlider *)sender
{
	unsigned long value = lround(sender.value);
	
	GPSLocation *loc = [self.trip.gpsLocations objectAtIndex:value];
	
	NSTimeInterval timeSinceStart = [loc.timestamp timeIntervalSinceDate:self.trip.startTime];
	
	NSInteger ti = (NSInteger)timeSinceStart;
	NSInteger seconds = ti % 60;
	NSInteger minutes = (ti / 60) % 60;
	NSInteger hours = (ti / 3600);
	
	self.speedLabel.text = [NSString stringWithFormat:@"%.2f mph",loc.speed.doubleValue];
	self.timeLabel.text = [NSString stringWithFormat:@"%02li:%02li:%02li",(long)hours,(long)minutes,(long)seconds];
	self.distanceLabel.text = [NSString stringWithFormat:@""];
	
	[self updateMarkerForSliderWithLocation:loc];
}

#pragma mark - GoogleMapViewDelegate

-(void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
	//Proceed only if Tap is in path
	float tolerance = powf(10.0,(-0.301*mapView.camera.zoom)+9.0731) / 500;
	
	if(!GMSGeometryIsLocationOnPath(coordinate, pathForTrip, NO,tolerance))
		return;
	
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
	{
		[self updateTapMarkerInMap:mapView withGPSLocation:closestLocation];
	}
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
	NSLog(@"Memory Warning!");
}

@end
