//
//  UIDevice+Performance.h
//  MvBox
//
//  Created by 清武黄 on 14-4-18.
//  Copyright (c) 2014年 51mvbox. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDeviceRank_Baseline                         10
#define kDeviceRank_AppleA4Class                     20   // Cortex-A8 class
#define kDeviceRank_AppleA5Class                     30   // Cortex-A9 class
#define kDeviceRank_AppleA5RAClass                   31   // Cortex-A9 class
#define kDeviceRank_AppleA5XClass                    35   // Cortex-A9 class
#define kDeviceRank_AppleA6Class                     40   // ARMv7s class
#define kDeviceRank_AppleA6XClass                    41   // ARMv7s class
#define kDeviceRank_AppleA7Class                     50   // ARM64 class
#define kDeviceRank_AppleA8LowClass                  55   // ARM64 class
#define kDeviceRank_AppleA8Class                     60   // ARM64 class
#define kDeviceRank_AppleA8XClass                    61   // ARM64 class
#define kDeviceRank_AppleA9Class                     70   // ARM64 class
#define kDeviceRank_AppleA9XClass                    71   // ARM64 class
#define kDeviceRank_LatestUnknown                    90
#define kDeviceRank_Simulator                        100

@interface UIDevice (Performance)

- (NSString *)deviceId;

- (BOOL)unsupport;
- (BOOL)poorPerformance;
- (BOOL)lowPerformance;
- (BOOL)normalPerformance;
- (BOOL)highPerformance;

+ (NSInteger)deviceRank;

+ (NSString *)currentDeviceString;
+ (NSString *)getCurrentDeviceModel;
+ (BOOL)isLowPerformanceDvice;

@end
