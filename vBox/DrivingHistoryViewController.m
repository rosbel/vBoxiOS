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
	DrivingHistory *drivingHistory;
	AppDelegate *appDelegate;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    // Do any additional setup after loading the view.
	appDelegate = [[UIApplication sharedApplication] delegate];
	drivingHistory = [appDelegate drivingHistory];
	
	formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterMediumStyle];
	[formatter setTimeZone:[NSTimeZone localTimeZone]];
	
	self.trips = drivingHistory.trips;
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
		Trip *trip = (Trip *)[self.trips objectAtIndex:[self.tableView indexPathForSelectedRow].row];
		TripDetailViewController* destination = (TripDetailViewController *)segue.destinationViewController;
		destination.trip = trip;
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

@end
