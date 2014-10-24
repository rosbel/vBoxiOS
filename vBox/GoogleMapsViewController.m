//
//  ViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "GoogleMapsViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface GoogleMapsViewController ()

@end

@implementation GoogleMapsViewController{
	GMSCameraPosition *camera;
	GMSMutablePath *completePath;
	GMSPolyline* polyline;
	NSMutableArray *pastLocations;
	NSMutableArray *markers;
	bool followMe;
	float currentZoom;
	AppDelegate *appDelegate;
	NSManagedObjectContext *context;
	Trip *currentTrip;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	appDelegate = [[UIApplication sharedApplication] delegate];
	context = [appDelegate managedObjectContext];
	currentTrip = [NSEntityDescription insertNewObjectForEntityForName:@"Trip" inManagedObjectContext:context];
	[currentTrip setStartTime:[NSDate date]];
	
	
	currentZoom = 15;
	followMe = YES;
	
	markers = [NSMutableArray array];
	completePath = [GMSMutablePath path];
	
	polyline = [GMSPolyline polylineWithPath:completePath];
	polyline.strokeColor = [UIColor redColor];
	polyline.strokeWidth = 5.0;
	polyline.geodesic = YES;
	polyline.map = self.MapView;
	
	pastLocations = [NSMutableArray array];
	
	_locationManager = [[CLLocationManager alloc] init];
	[_locationManager setDelegate:self];
	_locationManager.distanceFilter = 20;
	_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	
	[_locationManager requestWhenInUseAuthorization];
	[_locationManager requestAlwaysAuthorization];
	[_locationManager startUpdatingLocation];
	
	camera = [GMSCameraPosition cameraWithLatitude:39.490179
										 longitude:-98.081992
											  zoom:currentZoom];
	
	[_MapView setCamera:camera];
	_MapView.myLocationEnabled = YES;
	_MapView.settings.myLocationButton = YES;
	_MapView.settings.compassButton = YES;
	[_MapView setDelegate:self];
	
	UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	
	blurView.layer.masksToBounds = YES;
	
	blurView.layer.cornerRadius = 5.0;
	
	blurView.frame = self.stopRecordingButton.frame;
	
	[self.view insertSubview:blurView belowSubview:self.stopRecordingButton];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[_locationManager stopUpdatingLocation];
	[currentTrip setEndTime:[NSDate date]];
	[[appDelegate drivingHistory] addTripsObject:currentTrip];
	
	[appDelegate saveContext];
}

#pragma mark - Google Maps View Delegate

-(void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
	if(gesture)
	{
		followMe = NO;
	}
}

-(BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView
{
	followMe = YES;
	[_MapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:((CLLocation *)[pastLocations lastObject]).coordinate zoom:15]];
	return YES;
}

#pragma mark - Helper Methods

-(void)insertMarkerInMap:(GMSMapView *)myMapView withLocation:(CLLocation *)location andSnippet:(NSString *)snippet
{
	GMSMarker *marker = [[GMSMarker alloc]init];
	marker.position = location.coordinate;
	marker.appearAnimation = kGMSMarkerAnimationPop;
	marker.map = myMapView;
	marker.snippet = snippet;
	
	[markers addObject:marker];
}

-(void)insertPolylineInMap:(GMSMapView *)myMapView fromLocation:(CLLocation *)lastLocation toLocation:(CLLocation *)curLocation
{
	[completePath addCoordinate:curLocation.coordinate];

	[polyline setPath:completePath];
}

#pragma mark - CLLocation Delegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	CLLocation *newestLocation = [locations lastObject];
	CLLocation *prevLocation;
	
	unsigned long objCount = [locations count];
	unsigned long prevCount = [pastLocations count];
	
	if(objCount > 1)
	{
		prevLocation = [locations objectAtIndex:objCount - 2];
	}else if (prevCount > 1)
	{
		prevLocation = [pastLocations objectAtIndex:prevCount -2];
	}else
	{
		prevLocation = newestLocation;
	}
	
	//Update speed Label
	int speedMPH = [newestLocation speed] * 2.236936284;
	
	self.speedLabel.text = [NSString stringWithFormat:@"%d mph",speedMPH > 0 ? speedMPH : 0];
	

	//If distance between two points is greater than 200 m, then don't do anything
	if([newestLocation distanceFromLocation:prevLocation] > 500)
	{
		return; //ignore distances greater than 500
				// this causes things to stop working after one time 500m+ difference between location updates
	}
	
	[self logLocation:newestLocation persistent:YES];
//	[pastLocations addObject:newestLocation];
	
	if(newestLocation.speed > 60)
	{
		currentZoom = 10.0;
	}else if (newestLocation.speed < 60)
	{
		currentZoom = 15;
	}
	
	[self insertPolylineInMap:self.MapView fromLocation:prevLocation toLocation:newestLocation];
	
	if(followMe)
	{
		[_MapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:newestLocation.coordinate zoom:currentZoom]];
	}
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	if([error domain] == kCLErrorDomain )
	{
		return; //sometimes I get this error // fix later?
	}
	UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:[error localizedDescription] message:@"There was an error retrieving your location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[errorAlert show];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - UIView Delegate
-(BOOL)prefersStatusBarHidden
{
	return NO;
}

#pragma mark - Helper functions
-(void) applyEqualSizeConstraintsFromView:(UIView *)v1 toView:(UIView *)v2 includingTop:(BOOL)includeTop
{
	[v1 addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:v2 attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
	[v1 addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:v2 attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
	[v1 addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:v2 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
	if(includeTop)
	{
		[v1 addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:v2 attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
	}
}

#pragma mark - Core Data

-(void)logLocation:(CLLocation *)location persistent:(Boolean)persist
{
	double lat = location.coordinate.latitude;
	double lng = location.coordinate.longitude;
	double speed = location.speed;
	NSDate *time = location.timestamp;
	
	if(persist)
	{
		GPSLocation *newLocation = [NSEntityDescription insertNewObjectForEntityForName:@"GPSLocation" inManagedObjectContext:context];
		[newLocation setLatitude:[NSNumber numberWithDouble:lat]];
		[newLocation setLongitude:[NSNumber numberWithDouble:lng]];
		[newLocation setSpeed:[NSNumber numberWithDouble:speed]];
		[newLocation setTimestamp:time];
		[newLocation setTripInfo:currentTrip];
		
		[appDelegate saveContext];
	}
	
	[pastLocations addObject:location];
}

@end
