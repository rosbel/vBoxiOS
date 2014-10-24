//
//  AppDelegate.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/2/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DrivingHistory.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly,strong,nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly,strong,nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly,strong,nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly,strong,nonatomic) DrivingHistory *drivingHistory;

-(void)saveContext;
-(NSURL *)applicationDocumentsDirectory;


@end

