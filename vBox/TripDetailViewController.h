//
//  TripDetailViewController.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "AppDelegate.h"
#import "Trip.h"
#import "GPSLocation.h"
#import "DrivingHistory.h"

@interface TripDetailViewController : UIViewController <GMSMapViewDelegate>

@property (strong, nonatomic) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) NSArray *speedColors;
@property (strong, nonatomic) Trip *trip;

@end
