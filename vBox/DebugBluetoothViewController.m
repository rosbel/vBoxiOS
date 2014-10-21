//
//  DebugBluetoothViewController.m
//  vBox
//
//  Created by Rosbel Sanroman on 10/16/14.
//  Copyright (c) 2014 rosbelSanroman. All rights reserved.
//

#import "DebugBluetoothViewController.h"

@interface DebugBluetoothViewController ()

@end

@implementation DebugBluetoothViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.bluetoothController = [[BluetoothController alloc] init];
	self.bluetoothController.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didUpdateLogWithString:(NSString *)string
{
	self.textView.text = [self.textView.text stringByAppendingString:@"\n"];
	self.textView.text = [self.textView.text stringByAppendingString:string];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[self.bluetoothController disconnect];
}

-(void)didUpdateDiagnosticForKey:(NSString *)key withValue:(float)value
{
	
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
