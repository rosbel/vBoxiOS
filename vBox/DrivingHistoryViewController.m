//
//  DrivingHistoryViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "DrivingHistoryViewController.h"
#import "MyStyleKit.h"

@interface DrivingHistoryViewController ()

@property (strong, nonatomic) NSMutableDictionary *tripsByDate;
@property (strong, nonatomic) NSArray *sortedDays;

@end

@implementation DrivingHistoryViewController
{
	NSDateFormatter *dateFormatterWith12HRTime;
	NSDateFormatter *dateFormatterDateAndNoTime;
	AppDelegate *appDelegate;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    // Do any additional setup after loading the view.
	
	appDelegate = [[UIApplication sharedApplication] delegate];
	
	dateFormatterDateAndNoTime = [[NSDateFormatter alloc] init];
	[dateFormatterDateAndNoTime setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatterDateAndNoTime setTimeStyle:NSDateFormatterNoStyle];
	
	dateFormatterWith12HRTime = [[NSDateFormatter alloc] init];
	[dateFormatterWith12HRTime setDateStyle:NSDateFormatterShortStyle];
	[dateFormatterWith12HRTime setTimeStyle:NSDateFormatterMediumStyle];
	[dateFormatterWith12HRTime setTimeZone:[NSTimeZone systemTimeZone]];
	[dateFormatterWith12HRTime setDateStyle:NSDateFormatterNoStyle];
	
	self.trips = [[[appDelegate drivingHistory] trips] reversedOrderedSet];
	
	[self setupTripsByDate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupTripsByDate
{
	if(self.tripsByDate)
		self.tripsByDate = nil;
	self.tripsByDate = [NSMutableDictionary dictionary];
	for(Trip * trip in self.trips)
	{
		NSDate *beginningOfDate = [self dateAtBeginningOfDayForDate:trip.startTime];
		
		NSMutableArray *tempArray = self.tripsByDate[beginningOfDate];
		if(!tempArray)
		{
			tempArray = [NSMutableArray array];
			self.tripsByDate[beginningOfDate] = tempArray;
		}
		[tempArray addObject:trip];
	}
	
	self.sortedDays = [[[[self.tripsByDate allKeys] sortedArrayUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	if([segue.identifier  isEqualToString:@"tripDetailSegue"])
	{
		TripDetailViewController* destination = (TripDetailViewController *)segue.destinationViewController;
		destination.trip = [self tripFromIndexPath:((NSIndexPath *)sender)];
	}
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self.sortedDays count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [self stringForTitleInSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSDate *dateTitle = self.sortedDays[section];
	NSArray *tripsInDate = self.tripsByDate[dateTitle];
	return [tripsInDate count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"trip"];
	if(!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"trip"];
	}
	
	Trip *trip = [self tripFromIndexPath:indexPath];
	
	NSString *startTimeText = [dateFormatterWith12HRTime stringFromDate:trip.startTime];
	NSString *endTimeText = [dateFormatterWith12HRTime stringFromDate:trip.endTime];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",startTimeText,endTimeText];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"avg: %.2f mph - max: %.2f mph - (%.2f mi)",trip.avgSpeed.doubleValue,trip.maxSpeed.doubleValue,trip.totalMiles.doubleValue];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self performSegueWithIdentifier:@"tripDetailSegue" sender:indexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 30;
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
	header.textLabel.textColor = [UIColor whiteColor];
	header.tintColor = [MyStyleKit myOrange];
	header.opaque = YES;
	header.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 3];
	header.textLabel.textAlignment = NSTextAlignmentCenter;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
		Trip *tripToDelete = [self tripFromIndexPath:indexPath];
		[context deleteObject:tripToDelete];
		[appDelegate saveContext];
		NSDate *dateTitle = self.sortedDays[(NSUInteger) indexPath.section];
		NSArray *tripsInDate = self.tripsByDate[dateTitle];
		self.trips = appDelegate.drivingHistory.trips.reversedOrderedSet; //update
		[self setupTripsByDate]; //update dictionary
		if(tripsInDate.count == 1) //last object to be deleted
		{
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:(NSUInteger) indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		else
		{
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			[tableView headerViewForSection:indexPath.section].textLabel.text = [self stringForTitleInSection:indexPath.section];
		}
	}
}

#pragma mark - Helper Methods

- (NSString *)stringOfDateForSection:(NSInteger)section
{
	return [dateFormatterDateAndNoTime stringFromDate:self.sortedDays[section]];
}

- (double)totalMilesInSection:(NSInteger)section
{
	double mileSum = 0;
	NSArray *tripsInDate = self.tripsByDate[self.sortedDays[section]];
	for(Trip *trip in tripsInDate)
	{
		mileSum += trip.totalMiles.doubleValue;
	}
	return mileSum;
}

-(NSString *)stringForTitleInSection:(NSInteger)section
{
	double mileSum = [self totalMilesInSection:section];
	NSString *date = [self stringOfDateForSection:section];
	
	return [NSString stringWithFormat:@"%@   (%.2f mi)",date,mileSum];
}

- (Trip *)tripFromIndexPath:(NSIndexPath *)indexPath
{
	NSDate *dateTitle = self.sortedDays[(NSUInteger) indexPath.section];
	NSArray *tripsInDate = self.tripsByDate[dateTitle];
	Trip* trip = tripsInDate[(NSUInteger) indexPath.row];
	return trip;
}

- (NSDate *)dateAtBeginningOfDayForDate:(NSDate *)inputDate
{
	// Use the user's current calendar and time zone
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
	[calendar setTimeZone:timeZone];
	
	// Selectively convert the date components (year, month, day) of the input date
	NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth	| NSCalendarUnitDay fromDate:inputDate];
	
	// Set the time components manually
	[dateComps setHour:0];
	[dateComps setMinute:0];
	[dateComps setSecond:0];
	
	// Convert back
	NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
	return beginningOfDay;
}

- (NSDate *)dateByAddingYears:(NSInteger)numberOfYears toDate:(NSDate *)inputDate
{
	// Use the user's current calendar
	NSCalendar *calendar = [NSCalendar currentCalendar];
	
	NSDateComponents *dateComps = [[NSDateComponents alloc] init];
	[dateComps setYear:numberOfYears];
	
	NSDate *newDate = [calendar dateByAddingComponents:dateComps toDate:inputDate options:0];
	return newDate;
}

@end
