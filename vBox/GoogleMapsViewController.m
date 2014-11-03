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

@property (strong, nonatomic) IBOutlet UILabel *bluetoothRequiredLabel;
@property (weak, nonatomic) IBOutlet UIView *infoView;

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
	double metersFromStart;
	NSArray *styles;
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
	metersFromStart = 0;
	followMe = YES;
	
	self.bluetoothManager = [[BLEManager alloc] init];
	self.bluetoothManager.delegate = self;
	self.bluetoothDiagnostics = [NSMutableDictionary dictionary];
	
	[self setUpLocationManager];
	
	[self setUpGoogleMaps];
	
	[self setUpUIButtons];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[_MapView clear];
	_MapView = nil;
	[_locationManager stopUpdatingLocation];
	[currentTrip setEndTime:[NSDate date]];
	unsigned long count = currentTrip.gpsLocations.count;
	double avgSpeed = count > 0 ? sumSpeed / count : 0;
	[currentTrip setAvgSpeed:[NSNumber numberWithDouble:avgSpeed]];
	[currentTrip setMaxSpeed:[NSNumber numberWithDouble:maxSpeed]];
	[currentTrip setMinSpeed:[NSNumber numberWithDouble:minSpeed]];
	[[appDelegate drivingHistory] addTripsObject:currentTrip];
	[appDelegate saveContext];
}

#pragma mark - SetUp Methods

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
	UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	
	blurView.layer.masksToBounds = YES;
	
	blurView.layer.cornerRadius = 5.0;
	
	UIView *blurredLabel = [self.view viewWithTag:3];
	
	blurredLabel.layer.masksToBounds = YES;
	blurredLabel.layer.cornerRadius = 5.0;
	
	blurView.frame = self.stopRecordingButton.frame;
	
	[self.view insertSubview:blurView belowSubview:self.stopRecordingButton];
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
	CLLocation *newestLocation = [locations lastObject];
	
	//Ignore bad Accuracy
	if(newestLocation.horizontalAccuracy > 15) //maybe give user tolerance for bad accuracy?
	{
		if(newestLocation.horizontalAccuracy < 50)
			if(followMe)
				[_MapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:newestLocation.coordinate zoom:14]];
		
		return;
	}
	
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
	
	//If distance between two points is greater than 200 m, then don't do anything
	if([newestLocation distanceFromLocation:prevLocation] > 500)
	{
		return; //ignore distances greater than 500
				// this causes things to stop working after one time 500m+ difference between location updates
	}
	
	metersFromStart += [newestLocation distanceFromLocation:prevLocation];
	[self logLocation:newestLocation persistent:YES];
	
	[completePath addCoordinate:newestLocation.coordinate];
	
	[polyline setPath:completePath];
	
	double tolerance = powf(10.0,(-0.301*self.MapView.camera.zoom)+9.0731) / 2500.0;
	NSArray *lengths = @[@(tolerance),@(tolerance*1.5)];
	polyline.spans = GMSStyleSpans(polyline.path, styles, lengths, kGMSLengthGeodesic);
	
	if(followMe)
	{
		[_MapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:newestLocation.coordinate]];
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

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionCell" forIndexPath:indexPath];
	UILabel *key = (UILabel *)[cell viewWithTag:1];
	UILabel *val = (UILabel *)[cell viewWithTag:2];
	
	NSArray *keys = [[self.bluetoothDiagnostics allKeys] sortedArrayUsingSelector:@selector(compare:)];
	key.text = [keys objectAtIndex:indexPath.row];
	
	val.text = [NSString stringWithFormat:@"%@",(NSNumber *)[self.bluetoothDiagnostics objectForKey:key.text]];

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
	}
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
		[newLocation setMetersFromStart:[NSNumber numberWithDouble:metersFromStart]];
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
