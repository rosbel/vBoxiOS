//
//  AppDelegate.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "UtilityMethods.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize drivingHistory = _drivingHistory;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.

    // Initialize Google Maps SDK
    [GMSServices provideAPIKey:@"AIzaSyCuezG1N1vEXjN8WweYUhdYGzGhOCkqNsE"];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
}

#pragma mark - Core Data

-(void)saveContext
{
	NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	if(managedObjectContext != nil)
	{
		if([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
		{
			NSLog(@"Unresolved Error %@, %@", error, [error userInfo]);
//			abort(); //dont use abort in real app, only for debugging
		}
	}
}

-(NSManagedObjectContext *)managedObjectContext
{
	if(_managedObjectContext != nil)
	{
		return _managedObjectContext;
	}
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if(coordinator != nil)
	{
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[_managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return _managedObjectContext;
}

-(NSManagedObjectModel *)managedObjectModel
{
	if(_managedObjectModel != nil)
	{
		return _managedObjectModel;
	}
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"GPSInformation" withExtension:@"momd"];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return _managedObjectModel;
}

-(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if(_persistentStoreCoordinator != nil){
		return _persistentStoreCoordinator;
	}
	NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"GPSInformation.sqlite"];
	
	NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error])
	{
		NSLog(@"Unresolved Error %@, %@",error,[error userInfo]);
//		abort();
	}
	
	return _persistentStoreCoordinator;
}

-(DrivingHistory *)drivingHistory
{
	NSManagedObjectContext *context = [self managedObjectContext];
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DrivingHistory"];
	NSError *error;
	NSArray *objects = [context executeFetchRequest:request error:&error];
	if(error)
	{
		NSLog(@"Error: %@, %@",error,[error userInfo]);
	}
	
	if([objects count] == 0)
	{
		_drivingHistory = (DrivingHistory *)[NSEntityDescription insertNewObjectForEntityForName:@"DrivingHistory" inManagedObjectContext:context];
		[self saveContext];
	}
	else if([objects count] == 1)
	{
		for(DrivingHistory *history in objects)
		{
			_drivingHistory = history;
		}
	}
	return _drivingHistory;
}

- (void)forgetDrivingHistory
{
	_drivingHistory = nil;
}

#pragma mark - Application's Documents Directory
- (NSURL *)applicationDocumentsDirectory
{
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
