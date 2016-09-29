//
//  HPLiveViewController.m
//  HPLiveSDKDemo
//
//  Created by hp on 16/9/26.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import "HPLiveViewController.h"
#import "HPLiveSession.h"

@interface HPLiveViewController ()
{
    NSString *_liveSteamUrlStr;
}

@property (nonatomic, strong) HPLiveSession *liveSession;

@end

@implementation HPLiveViewController
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withLiveStreamUrlStr:(NSString *)streamUrlStr
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _liveSteamUrlStr = streamUrlStr;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.liveSession = [[HPLiveSession alloc] initWithLiveSteamUrl:_liveSteamUrlStr];
    _liveSession.showLiveView = _showBgView;
    [_liveSession start];
    
    [_liveSession pushStream];
}

#pragma mark - cancel Live
- (IBAction)cancelLiveAction:(id)sender {
    
    if (_liveSession) {
        [_liveSession stop];
    }
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
