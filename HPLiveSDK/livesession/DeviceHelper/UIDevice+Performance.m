//
//  UIDevice+Performance.m
//  MvBox
//
//  Created by 清武黄 on 14-4-18.
//  Copyright (c) 2014年 51mvbox. All rights reserved.
//

/*
 
 @"i386", @"x86_64",    // @"iPhone Simulator", @"iPhone Simulator",
 
 @"iPhone1,1",          // @"iPhone 2G",
 @"iPhone1,2",          // @"iPhone 3G",
 @"iPhone2,1",          // @"iPhone 3GS",
 @"iPhone3,1",          // @"iPhone 4(GSM)",
 @"iPhone3,2",          // @"iPhone 4(GSM Rev A)",
 @"iPhone3,3",          // @"iPhone 4(CDMA)",
 @"iPhone4,1",          // @"iPhone 4S",
 @"iPhone5,1",          // @"iPhone 5(GSM)",
 @"iPhone5,2",          // @"iPhone 5(GSM+CDMA)",
 @"iPhone5,3",          // @"iPhone 5c(GSM)",
 @"iPhone5,4",          // @"iPhone 5c(Global)",
 @"iPhone6,1",          // @"iphone 5s(GSM)",
 @"iPhone6,2",          // @"iphone 5s(Global)",
 
 @"iPod1,1",            // @"iPod Touch 1G",
 @"iPod2,1",            // @"iPod Touch 2G",
 @"iPod3,1",            // @"iPod Touch 3G",
 @"iPod4,1",            // @"iPod Touch 4G",
 @"iPod5,1",            // @"iPod Touch 5G",
 
 @"iPad1,1",            // @"iPad",
 @"iPad2,1",            // @"iPad 2(WiFi)",
 @"iPad2,2",            // @"iPad 2(GSM)",
 @"iPad2,3",            // @"iPad 2(CDMA)",
 @"iPad2,4",            // @"iPad 2(WiFi + New Chip)",
 @"iPad3,1",            // @"iPad 3(WiFi)",
 @"iPad3,2",            // @"iPad 3(GSM+CDMA)",
 @"iPad3,3",            // @"iPad 3(GSM)",
 @"iPad3,4",            // @"iPad 4(WiFi)",
 @"iPad3,5",            // @"iPad 4(GSM)",
 @"iPad3,6",            // @"iPad 4(GSM+CDMA)",
 
 @"iPad2,5",            // @"iPad mini (WiFi)",
 @"iPad2,6",            // @"iPad mini (GSM)",
 @"iPad2,7",            // @"ipad mini (GSM+CDMA)"
 
 */

#import "UIDevice+Performance.h"
#import "sys/utsname.h"

@interface DeviceModel: NSObject

@property(nonatomic) NSString   *platform;
@property(nonatomic) NSString   *name;
@property(nonatomic) NSInteger  rank;

@end

@implementation UIDevice (Performance)

- (BOOL)unsupport
{
    return NO;
}

- (NSString *)deviceId
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

- (BOOL)poorPerformance
{
    // low performance devices:
    NSArray *models = @[
                        @"iPhone1,1",
                        @"iPhone1,2",
                        @"iPhone2,1",
                        @"iPhone3,1",   // iPhone4
                        @"iPhone3,2",   // iPhone4
                        
                        @"iPod1,1",
                        @"iPod2,1",
                        @"iPod3,1",
                        @"iPod4,1",     // iPod Touch4
                        
                        @"iPad1,1",
                        @"iPad2,1",
                        @"iPad2,2",
                        @"iPad2,3"
                        ];
    
    NSInteger index = [models indexOfObject:[self deviceId]];
    
    return !!(index >= 0 && index < [models count]);
}

- (BOOL)lowPerformance
{
    // low performance devices:
    NSArray *models = @[
                        @"iPhone1,1",
                        @"iPhone1,2",
                        @"iPhone2,1",
                        @"iPhone3,1",   // iPhone4
                        @"iPhone3,2",   // iPhone4
                        @"iPhone3,3",   // iPhone4
                        @"iPhone4,1",
                        @"iPhone4,2",
                        @"iPhone4,3",
                        
                        @"iPod1,1",
                        @"iPod2,1",
                        @"iPod3,1",
                        @"iPod4,1",     // iPod Touch4
                        @"iPod5,1",
                        
                        @"iPad1,1",
                        @"iPad2,1",
                        @"iPad2,2",
                        @"iPad2,3",
                        @"iPad2,4",
                        ];
    
    NSInteger index = [models indexOfObject:[self deviceId]];

    return !!(index >= 0 && index < [models count]);
}

- (BOOL)normalPerformance
{
    // low performance devices:
    NSArray *models = @[
                        @"iPhone4,1",   // iPhone4S
                        @"iPhone4,2",
                        @"iPhone4,3",
                        
                        @"iPod5,1",     // iPod Touch5
                        ];
    
    NSInteger index = [models indexOfObject:[self deviceId]];
    
    return !!(index >= 0 && index < [models count]);
}

- (BOOL)highPerformance
{
    return !([self lowPerformance] || [self normalPerformance]);
}

+ (BOOL)isLowPerformanceDvice
{
    NSString *deviceMode = [UIDevice getCurrentDeviceModel];
    NSArray *models = @[
                        @"iPhone 2G",
                        @"iPhone 3G",
                        @"iPhone 3GS",
                        @"iPhone 4",   // iPhone4
                        @"iPhone 4",   // iPhone4
                        @"iPhone 4",   // iPhone4
                        @"iPhone 4S",
                        
                        @"iPod Touch 1G",
                        @"iPod Touch 2G",
                        @"iPod Touch 3G",
                        @"iPod Touch 4G",     // iPod Touch4
                        @"iPod Touch 5G",
                        
                        @"iPad 1G",
                        @"iPad Mini 1G",
                        @"iPad 2",
                        ];
    if([models containsObject:deviceMode])
        return YES;
    else
        return NO;
}

+ (NSString *)currentDeviceString
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

+ (NSString *)getCurrentDeviceModel
{
    NSString *deviceString = [UIDevice currentDeviceString];
    if ([deviceString isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    if ([deviceString isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"]) return @"iPhone 5c";
    if ([deviceString isEqualToString:@"iPhone5,4"]) return @"iPhone 5c";
    if ([deviceString isEqualToString:@"iPhone6,1"]) return @"iPhone 5s";
    if ([deviceString isEqualToString:@"iPhone6,2"]) return @"iPhone 5s";
    if ([deviceString isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"]) return @"iPhone 6s plus";
    
    if ([deviceString isEqualToString:@"iPod1,1"])   return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"])   return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"])   return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"])   return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPod5,1"])   return @"iPod Touch 5G";
    if ([deviceString isEqualToString:@"iPod6,1"])   return @"iPod Touch 5";
    if ([deviceString isEqualToString:@"iPod7,1"])   return @"iPod Touch 6";
    
    if ([deviceString isEqualToString:@"iPad1,1"])   return @"iPad 1G";
    
    if ([deviceString isEqualToString:@"iPad2,1"])   return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad2,2"])   return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad2,3"])   return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad2,4"])   return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad2,5"])   return @"iPad Mini 1G";
    if ([deviceString isEqualToString:@"iPad2,6"])   return @"iPad Mini 1G";
    if ([deviceString isEqualToString:@"iPad2,7"])   return @"iPad Mini 1G";
    
    if ([deviceString isEqualToString:@"iPad3,1"])   return @"iPad 3";
    if ([deviceString isEqualToString:@"iPad3,2"])   return @"iPad 3";
    if ([deviceString isEqualToString:@"iPad3,3"])   return @"iPad 3";
    if ([deviceString isEqualToString:@"iPad3,4"])   return @"iPad 4";
    if ([deviceString isEqualToString:@"iPad3,5"])   return @"iPad 4";
    if ([deviceString isEqualToString:@"iPad3,6"])   return @"iPad 4";
    
    if ([deviceString isEqualToString:@"iPad4,1"])   return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,2"])   return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,3"])   return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,4"])   return @"iPad Mini 2G";
    if ([deviceString isEqualToString:@"iPad4,5"])   return @"iPad Mini 2G";
    if ([deviceString isEqualToString:@"iPad4,6"])   return @"iPad Mini 2G";
    
    if ([deviceString isEqualToString:@"i386"])      return @"iPhone Simulator";
    if ([deviceString isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    return deviceString;
}






+ (NSInteger)deviceRank
{
    NSString *device = [UIDevice currentDeviceString];
    return [UIDevice deviceRank:device];
}

+ (NSInteger)deviceRank:(NSString *)name
{
        // Simulator
    if ([name isEqualToString:@"i386"]) return kDeviceRank_Simulator;
    if ([name isEqualToString:@"x86_64"]) return kDeviceRank_Simulator;
        
        // iPhone
    if ([name isEqualToString:@"iPhone1,1"]) return kDeviceRank_Baseline;       // iPhone
    if ([name isEqualToString:@"iPhone1,2"]) return kDeviceRank_Baseline;       // iPhone 3G
        
    if ([name isEqualToString:@"iPhone2,1"]) return kDeviceRank_Baseline;       // iPhone 3GS
        
    if ([name isEqualToString:@"iPhone3,1"]) return kDeviceRank_AppleA4Class;   // iPhone 4
    if ([name isEqualToString:@"iPhone3,2"]) return kDeviceRank_AppleA4Class;   // iPhone 4
    if ([name isEqualToString:@"iPhone3,3"]) return kDeviceRank_AppleA4Class;   // iPhone 4
        
    if ([name isEqualToString:@"iPhone4,1"]) return kDeviceRank_AppleA5Class;   // iPhone 4s
        
    if ([name isEqualToString:@"iPhone5,1"]) return kDeviceRank_AppleA6Class;   // iPhone 5
    if ([name isEqualToString:@"iPhone5,2"]) return kDeviceRank_AppleA6Class;   // iPhone 5
    if ([name isEqualToString:@"iPhone5,3"]) return kDeviceRank_AppleA6Class;   // iPhone 5c
    if ([name isEqualToString:@"iPhone5,4"]) return kDeviceRank_AppleA6Class;   // iPhone 5c
        
    if ([name isEqualToString:@"iPhone6,1"]) return kDeviceRank_AppleA7Class;   // iPhone 5s
    if ([name isEqualToString:@"iPhone6,2"]) return kDeviceRank_AppleA7Class;   // iPhone 5s
        
    if ([name isEqualToString:@"iPhone7,1"]) return kDeviceRank_AppleA8Class;   // iPhone 6 Plus
    if ([name isEqualToString:@"iPhone7,2"]) return kDeviceRank_AppleA8Class;   // iPhone 6
        
    if ([name isEqualToString:@"iPhone8,1"]) return kDeviceRank_AppleA9Class;   // iPhone 6S
    if ([name isEqualToString:@"iPhone8,2"]) return kDeviceRank_AppleA9Class;   // iPhone 6S Plus
    if ([name isEqualToString:@"iPhone8,4"]) return kDeviceRank_AppleA9Class;   // iPhone SE
    
        // iPod Touch
    if ([name isEqualToString:@"iPod1,1"]) return kDeviceRank_Baseline;         // iPod Touch
    if ([name isEqualToString:@"iPod2,1"]) return kDeviceRank_Baseline;         // iPod Touch 2G
    if ([name isEqualToString:@"iPod3,1"]) return kDeviceRank_Baseline;         // iPod Touch 3G
        
    if ([name isEqualToString:@"iPod4,1"]) return kDeviceRank_AppleA4Class;     // iPod Touch 4G
    if ([name isEqualToString:@"iPod5,1"]) return kDeviceRank_AppleA5Class;     // iPod Touch 5G
    if ([name isEqualToString:@"iPod7,1"]) return kDeviceRank_AppleA8LowClass;  // iPod Touch 6G
        
        // iPad / iPad mini
    if ([name isEqualToString:@"iPad1,1"]) return kDeviceRank_AppleA4Class;     // iPad
        
    if ([name isEqualToString:@"iPad2,1"]) return kDeviceRank_AppleA5Class;     // iPad 2
    if ([name isEqualToString:@"iPad2,2"]) return kDeviceRank_AppleA5Class;     // iPad 2
    if ([name isEqualToString:@"iPad2,3"]) return kDeviceRank_AppleA5Class;     // iPad 2
        
    if ([name isEqualToString:@"iPad2,4"]) return kDeviceRank_AppleA5RAClass;   // iPad 2
    if ([name isEqualToString:@"iPad2,5"]) return kDeviceRank_AppleA5RAClass;   // iPad mini
    if ([name isEqualToString:@"iPad2,6"]) return kDeviceRank_AppleA5RAClass;   // iPad mini
    if ([name isEqualToString:@"iPad2,7"]) return kDeviceRank_AppleA5RAClass;   // iPad mini
        
    if ([name isEqualToString:@"iPad3,1"]) return kDeviceRank_AppleA5XClass;    // iPad 3G
    if ([name isEqualToString:@"iPad3,2"]) return kDeviceRank_AppleA5XClass;    // iPad 3G
    if ([name isEqualToString:@"iPad3,3"]) return kDeviceRank_AppleA5XClass;    // iPad 3G
        
    if ([name isEqualToString:@"iPad3,4"]) return kDeviceRank_AppleA6XClass;    // iPad 4G
    if ([name isEqualToString:@"iPad3,5"]) return kDeviceRank_AppleA6XClass;    // iPad 4G
    if ([name isEqualToString:@"iPad3,6"]) return kDeviceRank_AppleA6XClass;    // iPad 4G
        
    if ([name isEqualToString:@"iPad4,1"]) return kDeviceRank_AppleA7Class;     // iPad Air
    if ([name isEqualToString:@"iPad4,2"]) return kDeviceRank_AppleA7Class;     // iPad Air
    if ([name isEqualToString:@"iPad4,3"]) return kDeviceRank_AppleA7Class;     // iPad Air
    if ([name isEqualToString:@"iPad4,4"]) return kDeviceRank_AppleA7Class;     // iPad mini 2G
    if ([name isEqualToString:@"iPad4,5"]) return kDeviceRank_AppleA7Class;     // iPad mini 2G
    if ([name isEqualToString:@"iPad4,6"]) return kDeviceRank_AppleA7Class;     // iPad mini 2G
        
    if ([name isEqualToString:@"iPad4,7"]) return kDeviceRank_AppleA7Class;     // iPad mini 3
    if ([name isEqualToString:@"iPad4,8"]) return kDeviceRank_AppleA7Class;     // iPad mini 3
    if ([name isEqualToString:@"iPad4,9"]) return kDeviceRank_AppleA7Class;     // iPad mini 3
        
    if ([name isEqualToString:@"iPad5,1"]) return kDeviceRank_AppleA8XClass;    // iPad mini 4
    if ([name isEqualToString:@"iPad5,2"]) return kDeviceRank_AppleA8XClass;    // iPad mini 4
    if ([name isEqualToString:@"iPad5,3"]) return kDeviceRank_AppleA8XClass;    // iPad Air 2
    if ([name isEqualToString:@"iPad5,4"]) return kDeviceRank_AppleA8XClass;    // iPad Air 2
        
    if ([name isEqualToString:@"iPad6,3"]) return kDeviceRank_AppleA9XClass;    // iPad Pro
    if ([name isEqualToString:@"iPad6,4"]) return kDeviceRank_AppleA9XClass;    // iPad Pro
        
    if ([name isEqualToString:@"iPad6,7"]) return kDeviceRank_AppleA9XClass;    // iPad Pro
    if ([name isEqualToString:@"iPad6,8"]) return kDeviceRank_AppleA9XClass;    // iPad Pro
    
    return kDeviceRank_LatestUnknown;
}

@end
