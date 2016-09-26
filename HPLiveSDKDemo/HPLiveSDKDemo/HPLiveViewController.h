//
//  HPLiveViewController.h
//  HPLiveSDKDemo
//
//  Created by hp on 16/9/26.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPLiveViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *showBgView;
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withLiveStreamUrlStr:(NSString *)streamUrlStr;
@end
