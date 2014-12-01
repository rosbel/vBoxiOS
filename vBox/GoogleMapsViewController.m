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
#import "MyStyleKit.h"

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
	BOOL followMe;
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
	BOOL showSpeed;
	BOOL bleOn;
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
	showSpeed = YES;
	bleOn = NO;
	
	self.speedOrDistanceLabel.userInteractionEnabled = YES;
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(speedLabelTapped)];
	[self.speedOrDistanceLabel addGestureRecognizer:tapGesture];
	
	self.bluetoothDiagnostics = [NSMutableDictionary dictionary];
	
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
	
	[self updateViewsBasedOnBLEButtonState:bleOn animate:NO];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[_MapView clear];
	_MapView = nil;
	[_locationManager stopUpdatingLocation];
	
	[self cleanUpBluetoothManager];
	
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
	
	[super viewWillDisappear:animated];
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
	
	[_MapView setPadding:UIEdgeInsetsMake(85, 0, 0, 5)];
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
	self.bleButton.layer.masksToBounds = YES;
	self.bleButton.layer.cornerRadius = 5.0;
	
	self.stopRecordingButton.layer.masksToBounds = YES;
	self.stopRecordingButton.layer.cornerRadius = 5.0;
	
	[self.stopRecordingButton setBackgroundImage:[MyStyleKit imageOfVBoxButtonWithButtonColor:self.stopRecordingButton.backgroundColor] forState:UIControlStateNormal];
	
	self.speedOrDistanceLabel.layer.masksToBounds = YES;
	self.speedOrDistanceLabel.layer.cornerRadius = 5.0;
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


#pragma mark - Button Action Methods

- (IBAction)stopRecordingButtonTapped:(id)sender {
	
	[self.navigationController popViewControllerAnimated:YES];
	[self.delegate didTapStopRecordingButton];
}

- (IBAction)bleButtonTapped:(UIButton *)sender {
	bleOn = !bleOn;
	if(bleOn)
	{
		[sender setImage:[UIImage imageNamed:@"bleOn"] forState:UIControlStateNormal];
		[self setUpBluetoothManager];
	}else
	{
		[sender setImage:[UIImage imageNamed:@"bleOff"] forState:UIControlStateNormal];
		[self cleanUpBluetoothManager];
	}
	[self updateViewsBasedOnBLEButtonState:bleOn animate:YES];
}

#pragma mark - Speed Label Methods

-(void)speedLabelTapped
{
	showSpeed = !showSpeed;
	[self updateSpeedLabelWithLocation:[pastLocations lastObject]];
}

-(void)updateSpeedLabelWithLocation:(CLLocation *)lastLocation
{
	if(showSpeed)
	{
		self.speedOrDistanceLabel.text = [NSString stringWithFormat:@" %.2f mph",lastLocation.speed * 2.23694];
	}else
	{
		self.speedOrDistanceLabel.text = [NSString stringWithFormat:@" %.2f mi",GMSGeometryLength(completePath) * 0.000621371];
	}
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
	
	
	[completePath addCoordinate:newestLocation.coordinate];
	
	[self updateSpeedLabelWithLocation:newestLocation];
	
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
	switch(state)
	{
		case BLEStateOn:
			self.bluetoothRequiredLabel.hidden = YES;
			if([[NSUserDefaults standardUserDefaults] boolForKey:@"connectToOBD"])
			{
				[self.bluetoothManager scanForPeripheralType:PeripheralTypeOBDAdapter];
			}
			else
			{
				[self.bluetoothManager scanForPeripheralType:PeripheralTypeBeagleBone];
			}
			break;
		case BLEStateOff:
			[SVProgressHUD showErrorWithStatus:@"Bluetooth Off"];
			break;
		case BLEStateResetting:
			[SVProgressHUD showErrorWithStatus:@"Bluetooth Resetting"];
			break;
		case BLEStateUnauthorized:
			[SVProgressHUD showErrorWithStatus:@"Bluetooth Unauthorized"];
			break;
		case BLEStateUnkown:
			[SVProgressHUD showErrorWithStatus:@"Bluetooth State Uknown"];
			break;
		case BLEStateUnsupported:
			[SVProgressHUD showErrorWithStatus:@"Bluetooth Unsupported"];
			break;
	}
	
	if(state != BLEStateOn)
	{
		self.bluetoothRequiredLabel.hidden = NO;
	}
}

-(void)didConnectPeripheral
{
	[SVProgressHUD showSuccessWithStatus:@"Connected"];
}

-(void)didBeginScanningForPeripheral
{
	[SVProgressHUD showWithStatus:@"Scanning.."];
}

-(void)didDisconnectPeripheral
{
	[SVProgressHUD showErrorWithStatus:@"Disconnected"];
	//try reconnecting
}

-(void)didStopScanning
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

-(void)updateViewsBasedOnBLEButtonState:(BOOL) state animate:(BOOL)animate
{
	if(state)
	{
		if(animate)
		{
			[UIView beginAnimations:@"ShowInfoView" context:nil];
			[UIView setAnimationBeginsFromCurrentState:NO];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDuration:0.25];
			[UIView setAnimationBeginsFromCurrentState:YES];
			[UIView setAnimationWillStartSelector:@selector(animationDidStart:context:)];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
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
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
			[UIView setAnimationDuration:0.25];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationWillStartSelector:@selector(animationDidStart:context:)];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		}
		[self.infoView setFrame:infoViewHiddenOffScreen];
		[self.MapView setFrame:[UIScreen mainScreen].bounds];
		if(animate)
		{
			[UIView commitAnimations];
		}
	}
}
- (void)animationDidStart:(NSString *)animationID context:(void *)context
{
	if([animationID isEqualToString:@"ShowInfoView"])
	{
		[self.infoView setHidden:NO];
	}
	self.bleButton.enabled = NO;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	if([animationID isEqualToString:@"HideInfoView"])
	{
		[self.infoView setHidden:YES];
	}
	self.bleButton.enabled = YES;
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
			NSNumber *bleSpeedMPH =[self.bluetoothDiagnostics objectForKey:@"Speed"];
			bleSpeedMPH = bleSpeedMPH ? [NSNumber numberWithDouble:(bleSpeedMPH.doubleValue * 0.621371)] : bleSpeedMPH;
			[bleData setSpeed:bleSpeedMPH];
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


#pragma mark - Clean UP

-(void)cleanUpBluetoothManager
{
	
	if(self.bluetoothManager.connected)
	{
		[self.bluetoothManager disconnect];
	}
	
	[self.bluetoothManager stopScanning];
	[self.bluetoothManager stopAdvertisingPeripheral];
	self.bluetoothManager = nil;
	
	[SVProgressHUD dismiss];
}


@end
