//
//  ViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "GoogleMapsViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "OLGhostAlertView.h"
#import "SVProgressHUD.h"

@interface GoogleMapsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *bluetoothRequiredLabel;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapViewToInfoViewConstraint;

@end

@implementation GoogleMapsViewController{
	GMSCameraPosition *camera;
	GMSMutablePath *completePath;
	GMSPolyline* polyline;
	NSMutableArray *pastLocations;
	bool followMe;
	AppDelegate *appDelegate;
	NSManagedObjectContext *context;
	Trip *currentTrip;
	double sumSpeed;
	double maxSpeed;
	double minSpeed;
	NSArray *styles;
	CGRect infoViewFrame;
	CGRect mapViewFrame;
	CGRect infoViewHiddenOffScreen;
}

#pragma mark - UIView Delegate Methods

- (void)viewDidLoad {
	[super viewDidLoad];
	
	appDelegate = [[UIApplication sharedApplication] delegate];
	context = [appDelegate managedObjectContext];
	
	currentTrip = [NSEntityDescription insertNewObjectForEntityForName:@"Trip" inManagedObjectContext:context];
	[currentTrip setStartTime:[NSDate date]];
	
	completePath = [GMSMutablePath path];
	pastLocations = [NSMutableArray array];
	
	styles = @[[GMSStrokeStyle solidColor:[UIColor colorWithRed:0.2666666667 green:0.4666666667 blue:0.6 alpha:1]],[GMSStrokeStyle solidColor:[UIColor colorWithRed:0.6666666667 green:0.8 blue:0.8 alpha:1]]];
	
	sumSpeed = 0;
	maxSpeed = 0;
	minSpeed = DBL_MAX;
	followMe = YES;
	
	self.bluetoothDiagnostics = [NSMutableDictionary dictionary];
	
	[self setUpBluetoothManager];//move this after click button
	
	[self setUpLocationManager];
	
	[self setUpGoogleMaps];
	
	[self setUpUIButtons];
}

-(void)viewDidLayoutSubviews
{
	infoViewFrame = self.infoView.frame;
	mapViewFrame = self.MapView.frame;
	infoViewHiddenOffScreen = self.infoView.frame;
	infoViewHiddenOffScreen.origin.y = [[UIScreen mainScreen] bounds].size.height;
	
	[self updateViewsBasedOnBluetoothState:self.bluetoothManager.state animate:NO];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[_MapView clear];
	_MapView = nil;
	[_locationManager stopUpdatingLocation];
	//Delete If no locations were recorded
	if(currentTrip.gpsLocations.count == 0)
	{
		[[appDelegate managedObjectContext] deleteObject:currentTrip];
		[appDelegate saveContext];
		return;
	}
	[currentTrip setEndTime:[NSDate date]];
	unsigned long count = currentTrip.gpsLocations.count;
	double avgSpeed = count > 0 ? sumSpeed / count : 0;
	[currentTrip setAvgSpeed:[NSNumber numberWithDouble:avgSpeed]];
	[currentTrip setMaxSpeed:[NSNumber numberWithDouble:maxSpeed]];
	[currentTrip setMinSpeed:[NSNumber numberWithDouble:minSpeed]];
	[currentTrip setTotalMiles:[NSNumber numberWithDouble:GMSGeometryLength(completePath)*0.000621371]];
	[[appDelegate drivingHistory] addTripsObject:currentTrip];
	[appDelegate saveContext];
	
	[super viewWillAppear:animated];
}

#pragma mark - SetUp Methods

-(void)setUpBluetoothManager
{
	self.bluetoothManager = [[BLEManager alloc] init];
	self.bluetoothManager.delegate = self;
}

-(void)setUpLocationManager
{
	_locationManager = [[CLLocationManager alloc] init];
	
	[_locationManager setDelegate:self];
	_locationManager.distanceFilter = kCLDistanceFilterNone; //Best Accuracy
	_locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
	_locationManager.activityType = CLActivityTypeAutomotiveNavigation;
	_locationManager.pausesLocationUpdatesAutomatically = YES;//help save battery life when user is stopped
	
	[_locationManager requestWhenInUseAuthorization];
	[_locationManager requestAlwaysAuthorization];
	[_locationManager startUpdatingLocation];
}

-(void)setUpGoogleMaps
{
	camera = [GMSCameraPosition cameraWithLatitude:39.490179
										 longitude:-98.081992
											  zoom:3];
	
	[_MapView setPadding:UIEdgeInsetsMake(40, 0, 0, 0)];
	[_MapView setCamera:camera];
	_MapView.myLocationEnabled = YES;
	_MapView.settings.myLocationButton = YES;
	_MapView.settings.compassButton = YES;
	[_MapView setDelegate:self];
	
	
	polyline = [GMSPolyline polylineWithPath:completePath];
	polyline.strokeColor = [UIColor grayColor];
	polyline.strokeWidth = 5.0;
	polyline.geodesic = YES;
	polyline.map = self.MapView;
}

-(void)setUpUIButtons
{
	
	self.stopRecordingButton.layer.masksToBounds = YES;
	self.stopRecordingButton.layer.cornerRadius = 5.0;
	
	self.speedLabel.layer.masksToBounds = YES;
	self.speedLabel.layer.cornerRadius = 5.0;
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
	return NO;
}


#pragma mark - Button Action

- (IBAction)stopRecordingButtonTapped:(id)sender {
	
	[self.navigationController popViewControllerAnimated:YES];
	[self.delegate didTapStopRecordingButton];
}

#pragma mark - CLLocation Delegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	
	unsigned long objCount = [locations count];
	unsigned long prevCount = [pastLocations count];
	
	CLLocation *newestLocation = [locations lastObject];
	CLLocation *prevLocation;
	
	if(followMe && prevCount < 1 && newestLocation.horizontalAccuracy < 70)
	{
		[self.MapView animateToLocation:newestLocation.coordinate];
		if(self.MapView.camera.zoom < 10)
			[self.MapView animateToZoom:15];
	}
	//Ignore bad Accuracy
	if(newestLocation.horizontalAccuracy > 30) //maybe give user tolerance for bad accuracy?
	{
		return;
	}
	
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
	double speedMPH = ([newestLocation speed] * 2.236936284);
	speedMPH = speedMPH >= 0 ? speedMPH : 0;
	
	if(speedMPH < minSpeed)
	{
		minSpeed = speedMPH;
	}
	if(speedMPH > maxSpeed)
	{
		maxSpeed = speedMPH;
	}
	sumSpeed += speedMPH;
	
	self.speedLabel.text = [NSString stringWithFormat:@"%.2f mph",speedMPH];
	
	[completePath addCoordinate:newestLocation.coordinate];
	
	[self logLocation:newestLocation persistent:YES];
	
	[polyline setPath:completePath];
	
	double tolerance = powf(10.0,(-0.301*self.MapView.camera.zoom)+9.0731) / 2500.0;
	NSArray *lengths = @[@(tolerance),@(tolerance*1.5)];
	polyline.spans = GMSStyleSpans(polyline.path, styles, lengths, kGMSLengthGeodesic);
	
	if(followMe)
	{
		[_MapView animateToLocation:newestLocation.coordinate];
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

#pragma mark - UICollection Data Source Delegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.bluetoothDiagnostics.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *keys = [[self.bluetoothDiagnostics allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSString *key = [keys objectAtIndex:indexPath.row];
	
	UICollectionViewCell *cell;
	
	cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionCell" forIndexPath:indexPath];
	UILabel *keyLabel = (UILabel *)[cell viewWithTag:1];
	UILabel *valLabel = (UILabel *)[cell viewWithTag:2];
	keyLabel.text = key;
	valLabel.text = [NSString stringWithFormat:@"%@",(NSNumber *)[self.bluetoothDiagnostics objectForKey:key]];
	return cell;
}

#pragma mark - BLEManager Delegate

-(void)didChangeBluetoothState:(BLEState)state
{
	if(state == BLEStateOn)
	{
		self.bluetoothRequiredLabel.hidden = YES;
		
		if(self.bluetoothManager.connected)
		{
			[self.bluetoothManager setNotifyValue:YES];
		}
		else
		{
			[self.bluetoothManager scanForPeripheralType:PeripheralTypeOBDAdapter];
		}
	}else
	{
		self.bluetoothRequiredLabel.hidden = NO;
		
		[SVProgressHUD showErrorWithStatus:@"Bluetooth turned off"];
	}
	
	[self updateViewsBasedOnBluetoothState:state animate:YES];
}

-(void)didConnectPeripheral
{
	[SVProgressHUD showSuccessWithStatus:@"Connected"];
}

-(void)didBeginScanningForPeripheral
{
	[SVProgressHUD showWithStatus:@"Scanning.."];
}

-(void)didStopScanning
{
	
}

-(void)didUpdateDebugLogWithString:(NSString *)string
{
	
}

-(void)didUpdateDiagnosticForKey:(NSString *)key withValue:(NSNumber *)value
{
	[self.bluetoothDiagnostics setObject:value forKey:key];
	[self.collectionView reloadData];
}

-(void)didUpdateDiagnosticForKey:(NSString *)key withMultipleValues:(NSArray *)values
{
	
}

#pragma mark - Layout Methods

-(void)updateViewsBasedOnBluetoothState:(BLEState) state animate:(BOOL)animate
{
	if(state == BLEStateOn)
	{
		[self.infoView setHidden:NO];
		if(animate)
		{
			[UIView beginAnimations:@"ShowInfoView" context:nil];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
			[UIView setAnimationDuration:0.25];
		}
		[self.infoView setFrame:infoViewFrame];
		[self.MapView setFrame:mapViewFrame];
		if(animate)
		{
			[UIView commitAnimations];
		}
	}else
	{
		if(animate)
		{
			[UIView beginAnimations:@"HideInfoView" context:nil];
			[UIView setAnimationDelay:1];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
			[UIView setAnimationDuration:0.25];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		}
		[self.infoView setFrame:infoViewHiddenOffScreen];
		[self.MapView setFrame:[UIScreen mainScreen].bounds];
//		[self.infoView setHidden:YES];
		if(animate)
		{
			[UIView commitAnimations];
		}
	}
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	if([animationID isEqualToString:@"HideInfoView"])
	{
		[self.infoView setHidden:YES];
	}
}

#pragma mark - Core Data

-(void)logLocation:(CLLocation *)location persistent:(Boolean)persist
{
	double lat = location.coordinate.latitude;
	double lng = location.coordinate.longitude;
	double speedMPH = location.speed >= 0 ? location.speed * 2.236936284 : 0;
	NSDate *time = location.timestamp;
	
	if(persist)
	{
		GPSLocation *newLocation = [NSEntityDescription insertNewObjectForEntityForName:@"GPSLocation" inManagedObjectContext:context];
		[newLocation setLatitude:[NSNumber numberWithDouble:lat]];
		[newLocation setLongitude:[NSNumber numberWithDouble:lng]];
		[newLocation setSpeed:[NSNumber numberWithDouble:speedMPH]];
		[newLocation setMetersFromStart:[NSNumber numberWithDouble:GMSGeometryLength(completePath)]];
		[newLocation setTimestamp:time];
		[newLocation setTripInfo:currentTrip];
		
		if(self.bluetoothManager.connected)
		{
			
			BluetoothData *bleData = [NSEntityDescription insertNewObjectForEntityForName:@"BluetoothData" inManagedObjectContext:context];
			NSNumber *speedMPH =[self.bluetoothDiagnostics objectForKey:@"Speed"];
			speedMPH = speedMPH ? [NSNumber numberWithDouble:(speedMPH.doubleValue * 0.621371)] : speedMPH;
			[bleData setSpeed:speedMPH];
			[bleData setAmbientTemp:[self.bluetoothDiagnostics objectForKey:@"Ambient Temp"]];
			[bleData setBarometric:[self.bluetoothDiagnostics objectForKey:@"Barometric"]];
			[bleData setRpm:[self.bluetoothDiagnostics objectForKey:@"RPM"]];
			[bleData setIntakeTemp:[self.bluetoothDiagnostics objectForKey:@"Intake Temp"]];
			[bleData setFuel:[self.bluetoothDiagnostics objectForKey:@"Fuel"]];
			[bleData setEngineLoad:[self.bluetoothDiagnostics objectForKey:@"Engine Load"]];
			[bleData setDistance:[self.bluetoothDiagnostics objectForKey:@"Distance"]];
			[bleData setCoolantTemp:[self.bluetoothDiagnostics objectForKey:@"Coolant Temp"]];
			[bleData setThrottle:[self.bluetoothDiagnostics objectForKey:@"Throttle"]];
			//Set AccelX,Y,Z
			[newLocation setBluetoothInfo:bleData];
		}
		[appDelegate saveContext];
		//Check if Bluetooth is on, and populate DB with recent values
	}
	
	[pastLocations addObject:location];
}

@end
