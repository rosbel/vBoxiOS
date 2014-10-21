//
//  DebugBluetoothViewController.h
//  vBox
//
//  Created by Rosbel Sanroman on 10/16/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothController.h"

@interface DebugBluetoothViewController : UIViewController <UITextViewDelegate, BluetoothControllerDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) BluetoothController *bluetoothController;

@end
