//
//  TripDetailViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "TripDetailViewController.h"

@interface TripDetailViewController ()

@end

@implementation TripDetailViewController
{
	GMSCameraPosition *camera;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	for(GPSLocation *gpsLoc in self.trip.gpsLocations)
	{
		NSLog(@"Speed = %@",gpsLoc.speed);
	}
	
	GPSLocation *middle = [self.trip.gpsLocations objectAtIndex:[self.trip.gpsLocations count]/2];
	camera = [GMSCameraPosition cameraWithLatitude:[middle.latitude doubleValue]
										 longitude:[middle.longitude doubleValue]
											  zoom:13];
	
	[self.mapView setCamera:camera];
	self.mapView.settings.compassButton = YES;
	[self.mapView setDelegate:self];
	
	GMSMutablePath *path = [GMSMutablePath path];
	
	NSMutableArray *speeds = [NSMutableArray array];
	NSMutableArray *time = [NSMutableArray array];
	NSDate *startTime = self.trip.startTime;
	
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatter setMaximumFractionDigits:3];
	[formatter setRoundingMode: NSNumberFormatterRoundUp];
	
	int totalLabels = 5;
	int x = (int)[self.trip.gpsLocations count];
	int segments = totalLabels / totalLabels;
	
	int i = 0;
	for(GPSLocation *gpsLoc in self.trip.gpsLocations)
	{
		[path addLatitude:[gpsLoc.latitude doubleValue] longitude:[gpsLoc.longitude doubleValue]];
		[speeds addObject:gpsLoc.speed];
		
		
		NSNumber *secondsFromStart = [NSNumber numberWithDouble:[gpsLoc.timestamp timeIntervalSinceDate:startTime]];
		if(i % segments == 0)
		{
			[time addObject:[formatter stringFromNumber:secondsFromStart]];
		}
		i++;
	}
	
	GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
	polyline.strokeWidth = 5;
	polyline.strokeColor = [UIColor greenColor];
	polyline.geodesic = YES;
	polyline.map = self.mapView;
	
	[self setUpLineChartwithData:speeds andTimeArray:time];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUpLineChartwithData:(NSArray *)array andTimeArray:(NSArray *)time
{
	PNLineChart * lineChart = self.speedChart;
	lineChart.yLabelFormat = @"%1.1f";
	lineChart.backgroundColor = [UIColor clearColor];
	[lineChart setXLabels:time];
	//        lineChart.showCoordinateAxis = YES;
	
	// Line Chart Nr.1

	PNLineChartData *data01 = [PNLineChartData new];
	data01.color = PNFreshGreen;
	data01.itemCount = array.count;
	data01.inflexionPointStyle = PNLineChartPointStyleCycle;
	data01.getData = ^(NSUInteger index) {
		CGFloat yValue = [array[index] floatValue];
		return [PNLineChartDataItem dataItemWithY:yValue];
	};
	
	lineChart.chartData = @[data01];
	[lineChart strokeChart];
	
	lineChart.delegate = self;
	
//	[viewController.view addSubview:lineChartLabel];
//	[viewController.view addSubview:lineChart];
	
//	viewController.title = @"Line Chart";

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Helper Methods

-(UIColor *)colorBasedOnMPHSpeed:(int)speed
{
	if(speed >= 85)
	{
		return [UIColor blueColor];
	}
	else if(speed >= 60 && speed < 85)
	{
		return [UIColor greenColor];
	}
	else if(speed >= 40 && speed < 60)
	{
		return [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
	}
	else if(speed >= 30 && speed < 40)
	{
		return [UIColor yellowColor];
	}
	else if(speed >= 20 && speed < 30)
	{
		return [UIColor orangeColor];
	}
	else if(speed >= 1 && speed < 20)
	{
		return [UIColor redColor];
	}
	else
	{
		return [UIColor blackColor];
	}
}

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
