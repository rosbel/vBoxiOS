//
//  DrivingHistoryViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/23/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "DrivingHistoryViewController.h"
#import "AppDelegate.h"

@interface DrivingHistoryViewController ()

@end

@implementation DrivingHistoryViewController
{
	NSDateFormatter *formatter;
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
	
	formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterMediumStyle];
	[formatter setTimeZone:[NSTimeZone localTimeZone]];
	
	self.trips = [[appDelegate drivingHistory] trips];
	
//	NSDate *startDate = [self dateAtBeginningOfDayForDate:[NSDate date]];
//	NSDate *endDate = [self dateByAddingYears:1 toDate:startDate];
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	if([segue.identifier  isEqualToString:@"tripDetailSegue"])
	{
		TripDetailViewController* destination = (TripDetailViewController *)segue.destinationViewController;
		destination.trip = (Trip *)[self.trips objectAtIndex:[self.tableView indexPathForSelectedRow].row];
	}
}

#pragma mark - Table View Delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.trips count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"trip"];
	if(!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"trip"];
	}
	Trip* trip = (Trip *)[self.trips objectAtIndex:indexPath.row];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	NSString *startTimeText = [formatter stringFromDate:trip.startTime];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	NSString *endTimeText = [formatter stringFromDate:trip.endTime];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",startTimeText,endTimeText];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"avg: %.2f mph - max: %.2f mph - (%.2f mi)",trip.avgSpeed.doubleValue,trip.maxSpeed.doubleValue,trip.totalMiles.doubleValue];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self performSegueWithIdentifier:@"tripDetailSegue" sender:indexPath];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
		
		[context deleteObject:[self.trips objectAtIndex:indexPath.row]];
		[appDelegate saveContext];
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

#pragma mark - Helper Methods

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
