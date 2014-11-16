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
@property (weak, nonatomic) IBOutlet UIButton *fullScreenButton;
@property (weak, nonatomic) IBOutlet UIButton *followMeButton;

@end

@implementation TripDetailViewController{
	GMSCoordinateBounds *cameraBounds;
	BOOL followingMe;
	BOOL showRealTime;
	NSDateFormatter *dateFormatter;
}

@synthesize pathForTrip;
@synthesize GPSLocationsForTrip;
@synthesize speedDivisions;

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.speedColors = @[[UIColor redColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor greenColor]];
	
	self.fullScreenButton.layer.masksToBounds = YES;
	self.fullScreenButton.layer.cornerRadius = 5.0;
	
	self.followMeButton.layer.masksToBounds = YES;
	self.followMeButton.layer.cornerRadius = 5.0;
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm:ss"];
	showRealTime = NO;
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTimeLabel)];
	self.timeLabel.userInteractionEnabled = YES;
	[self.timeLabel addGestureRecognizer:tapRecognizer];
	
	followingMe = NO;
	
	self.GPSLocationsForTrip = self.trip.gpsLocations;
	[self setUpGoogleMaps];
	[self.speedGauge setUpWithUnits:@"MPH" max:150 startAngle:90 endAngle:270];
	[self.fuelGauge setUpWithUnits:@"Fuel %" max:100 startAngle:90 endAngle:270];
	[self.RPMGauge setUpWithUnits:@"RPM" max:10000 startAngle:90 endAngle:270];
	[self.tripSlider setMaximumValue:self.GPSLocationsForTrip.count-1];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:cameraBounds withPadding:40];
	[self.mapView animateWithCameraUpdate:update];
}

#pragma mark - Setup

- (void) setUpGoogleMaps
{
	[self.mapView setPadding:UIEdgeInsetsMake(10, 0, 0, 0)];
	
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
	
	self.speedDivisions = [self calculateSpeedBoundaries];
	
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
	CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(location.latitude.doubleValue, location.longitude.doubleValue);
	if(!self.markerForSlider)
	{
		self.markerForSlider = [GMSMarker markerWithPosition:coordinate];
		[self.markerForSlider setIcon:[UIImage imageNamed:@"currentLocation"]];
		[self.markerForSlider setGroundAnchor:CGPointMake(0.5, 0.5)];
		[self.markerForSlider setMap:self.mapView];
		self.followMeButton.hidden = NO;
	}else
	{
		[CATransaction begin];
		[CATransaction setAnimationDuration:0.001];
		[self.markerForSlider setPosition:coordinate];
		[CATransaction commit];
	}
	if(followingMe)
		[self.mapView animateToLocation:coordinate];
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

/*
 // Find the points to divide the line by color
 var color_division = [];
 for (i = 0; i < colors.length - 1; i++) {
 color_division[i] = min + (i + 1) * (max - min) / colors.length;
 }
 color_division[color_division.length] = max;
 */
-(NSArray *)calculateSpeedBoundaries
{
	double max = self.trip.maxSpeed.doubleValue;
	double min = self.trip.minSpeed.doubleValue;
	NSMutableArray *colorDivision = [NSMutableArray array];
	for(int i = 0; i < self.speedColors.count-1; i++)
	{
		double bound = (min + (i+1) * (max-min)) / self.speedColors.count;
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
	
	GPSLocation *loc = [self.GPSLocationsForTrip objectAtIndex:value];
	
	
	if(showRealTime)
	{
		self.timeLabel.text = [dateFormatter stringFromDate:loc.timestamp];
	}
	else
	{
		NSTimeInterval timeSinceStart = [loc.timestamp timeIntervalSinceDate:self.trip.startTime];
		NSInteger ti = (NSInteger)timeSinceStart;
		NSInteger seconds = ti % 60;
		NSInteger minutes = (ti / 60) % 60;
		NSInteger hours = (ti / 3600);
		self.timeLabel.text = [NSString stringWithFormat:@"%02li:%02li:%02li",(long)hours,(long)minutes,(long)seconds];
	}
	
	
	self.speedLabel.text = [NSString stringWithFormat:@"%.2f mph",loc.speed.doubleValue];
	self.distanceLabel.text = [NSString stringWithFormat:@"%.2f mi",(loc.metersFromStart.doubleValue * 0.000621371)];
	
	
	//GPS Speed
	[self.speedGauge setValue:loc.speed.floatValue animated:NO];
	
	if(loc.bluetoothInfo)
	{
		if(self.fuelGauge.hidden)
			self.RPMGauge.hidden = NO;
		if(self.fuelGauge.hidden)
			self.fuelGauge.hidden = NO;
		[self.RPMGauge setValue:loc.bluetoothInfo.rpm.floatValue animated:NO];
		[self.fuelGauge setValue:loc.bluetoothInfo.fuel.floatValue animated:NO];
		[self.speedGauge setValue:loc.bluetoothInfo.speed.floatValue animated:NO];
	}
	
	[self updateMarkerForSliderWithLocation:loc];
}

#pragma mark - MyLocationButton Event

- (IBAction)fullScreenButtonTapped:(UIButton *)sender
{
	GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:cameraBounds withPadding:40];
	[self.mapView animateWithCameraUpdate:update];
}

- (IBAction)followMeButtonTapped:(UIButton *)sender
{
	followingMe = !followingMe;
	if(followingMe)
	{
		[sender setImage:[UIImage imageNamed:@"followMeOn"] forState:UIControlStateNormal];
		[self.mapView animateToLocation:self.markerForSlider.position];
	}
	else
	{
		[sender setImage:[UIImage imageNamed:@"followMeOff"] forState:UIControlStateNormal];
	}
}
#pragma mark - Time Label tapped
-(void) didTapTimeLabel
{
	showRealTime = !showRealTime;
	[self sliderValueChanged:self.tripSlider];
}

#pragma mark - Sharing Event

- (IBAction)shareButtonTapped:(id)sender
{
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMddHHmmssSSS"];
	
	NSMutableString *log = [[NSMutableString alloc] init];
	[log appendFormat:@"Timestamp Lat Long Speed-MPH Fuel-%% RPM-rev Throttle-%% \n"];
	for(GPSLocation *loc in self.GPSLocationsForTrip)
	{
		NSString *date = [formatter stringFromDate:loc.timestamp];
		[log appendFormat:@"%@ %lf %lf %lf ",date,loc.latitude.doubleValue,loc.longitude.doubleValue,loc.speed.doubleValue];
		if(loc.bluetoothInfo)
		{
			[log appendFormat:@"%@ %@ %@ ",loc.bluetoothInfo.fuel,loc.bluetoothInfo.rpm,loc.bluetoothInfo.throttle];
		}
		[log appendString:@" \n"];
	}
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[log] applicationActivities:nil];
	activityViewController.excludedActivityTypes = @[UIActivityTypeAddToReadingList,UIActivityTypeAirDrop,UIActivityTypeAssignToContact,UIActivityTypePostToFacebook,UIActivityTypePostToTwitter,UIActivityTypeSaveToCameraRoll,UIActivityTypePostToTencentWeibo,UIActivityTypeMessage];
	
	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - GoogleMapViewDelegate

-(void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
	if(gesture)
	{
		if(followingMe)
		{
			[self followMeButtonTapped:self.followMeButton];
		}
	}
}

-(void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
	//Proceed only if Tap is in path
	float tolerance = powf(10.0,(-0.301*mapView.camera.zoom)+9.0731) / 500;
	
	if(!GMSGeometryIsLocationOnPathTolerance(coordinate, pathForTrip, NO, tolerance))
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
