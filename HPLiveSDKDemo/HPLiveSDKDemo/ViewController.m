//
//  ViewController.m
//  HPLiveSDKDemo
//
//  Created by hp on 16/9/26.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import "ViewController.h"
#import "HPLiveViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (IBAction)beginLiveAction:(id)sender {
    NSString *liveUrlStr = _liveUrlTextField.text;
    
    HPLiveViewController *liveVC = [[HPLiveViewController alloc] initWithNibName:@"HPLiveViewController" bundle:nil withLiveStreamUrlStr:liveUrlStr];
    [self.navigationController pushViewController:liveVC animated:YES];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
