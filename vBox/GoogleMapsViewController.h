//
//  ViewController.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "UICountingLabel.h"
#import "AppDelegate.h"
#import "GPSLocation.h"
#import "DrivingHistory.h"
#import "Trip.h"

@protocol GoogleMapsViewControllerDelegate <NSObject>

-(void)didTapStopRecordingButton;

@end

@interface GoogleMapsViewController : UIViewController <CLLocationManagerDelegate, GMSMapViewDelegate>

@property (strong,nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet GMSMapView *MapView;
@property (strong, nonatomic) IBOutlet UIButton *stopRecordingButton;
@property (strong, nonatomic) IBOutlet UICountingLabel *countingLabel;
@property (strong, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak  , nonatomic) id delegate;

@end

