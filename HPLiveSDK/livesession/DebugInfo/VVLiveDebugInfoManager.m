//
//  VVLiveDebugInfoManager.m
//  livesession
//
//  Created by hp on 16/7/18.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import "VVLiveDebugInfoManager.h"

#define DEFAULT_FORMAT(logTime) [NSString stringWithFormat:@"I %@ VVLIVE", logTime]
#define LOG_FILE_NAME(devicename, osname, time)  [NSString stringWithFormat:@"%@-%@-%@.log", devicename, osname, time]
#define LOG_FILE_WITH_NAME(devicename, osname, time, name)  [NSString stringWithFormat:@"%@-%@-%@-%@.log", devicename, osname, time, name]

@implementation VVLiveDebugInfoManager
{
    uint64_t _firstFrameTimeStamp;  //第一帧的时间戳，为了计算当前帧属于第几秒
    
    NSMutableData *_logData;        //日志data
    char *filePath;
    FILE *_fp;
}

-(id)init
{
    self = [super init];
    if (self) {
        filePath = [[self class] getFilePath];
        _fp = fopen(filePath, "wb");
    }
    return self;
}

-(id)initWithFileName:(NSString *)fileName
{
    self = [super init];
    if (self) {
        filePath = [[self class] getFilePathWithName:fileName];
        _fp = fopen(filePath, "wb");
    }
    return self;
}

-(void)logFeedDataWithFrameIndex:(NSInteger)index
{
    NSString *logStr = [NSString stringWithFormat:@"%@ vvlive_yunce_encode_test : push2encode, frameIndex=%@\n",DEFAULT_FORMAT([[self class] currentTimeFormat]), @(index)];
    NSData *logData = [logStr dataUsingEncoding:NSUTF8StringEncoding];
    fwrite(logData.bytes, 1,logData.length,_fp);

}

-(void)logOutDataWithFrameInfo:(VVLiveDebugInfo *)frameDebugInfo
{
    if (frameDebugInfo.frameCount == 1) {
        _firstFrameTimeStamp = frameDebugInfo.frameTimeStamp;
    }
    
    NSString *logStr = [NSString stringWithFormat:@"%@ vvlive_yunce_encode_test : gotEncodeData, frameIndex=%@, frameType=%@, frameSize=%@, timestamp=%@, now=%@, seconds=%@, bitrate=%@, framerate=%@\n",
                        DEFAULT_FORMAT([[self class] currentTimeFormat]),
                        @(frameDebugInfo.frameCount),
                        @(frameDebugInfo.frameType),
                        @(frameDebugInfo.length),
                        [[self class] timeStampFormat:frameDebugInfo.frameTimeStamp],
                        [[self class] timeStampFormat:frameDebugInfo.currentTime],
                        @([self inSecondWithTimeStamp:frameDebugInfo.frameTimeStamp]),
                        @(frameDebugInfo.videoBitRate/1024),
                        @(frameDebugInfo.videoFrameRate)];
    
    NSData *logData = [logStr dataUsingEncoding:NSUTF8StringEncoding];
    fwrite(logData.bytes, 1,logData.length,_fp);
}

-(void)logBitRateChangedFrom:(uint64_t)sourceBitRate toBitRate:(uint64_t)destBitRate FrameRateChangedFrom:(uint64_t)sourceFrameRate toFrameRate:(uint64_t)destFrameRate
{
    NSString *logStr = [NSString stringWithFormat:@"%@ vvlive_yunce_encode_test : changeBitrateFramerate, oldBitrate=%d, newBitrate=%d, oldFramerate=%d, newBitrate=%d, success=%d\n",DEFAULT_FORMAT([[self class] currentTimeFormat]),sourceBitRate, destBitRate, sourceFrameRate, destFrameRate, 1];
    NSData *logData = [logStr dataUsingEncoding:NSUTF8StringEncoding];
    fwrite(logData.bytes, 1,logData.length,_fp);
    
}

-(void)log:(NSString *)logStr
{
    NSData *logData = [logStr dataUsingEncoding:NSUTF8StringEncoding];
    fwrite(logData.bytes, 1,logData.length,_fp);
}

#pragma mark - info format
+(NSString *)timeStampFormat:(uint64_t)timeStamp
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    double timeStampForSecond = (double)timeStamp/1000;
    NSString *formatDateStr = [dateFormatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSince1970:timeStampForSecond]];
    return formatDateStr;
}

+(NSString *)currentTimeFormat
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm:ss.SSS"];
    NSString *formatDateStr = [dateFormatter stringFromDate:[NSDate date]];
    return formatDateStr;
}

-(uint64_t)inSecondWithTimeStamp:(uint64_t)timeStamp
{
    uint64_t inSecond = timeStamp - _firstFrameTimeStamp;
    if (inSecond <= 0) {
        inSecond = 0;
    }
    
    return inSecond/1000;
}

#pragma mark - path make
+(char*)getFilePathWithName:(NSString *)name
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *strName = LOG_FILE_WITH_NAME([[UIDevice currentDevice] model] ,[[UIDevice currentDevice] systemVersion], [[self class] fileNameTime], name);
    
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:strName];
    
    NSUInteger len = [writablePath length];
    
    char *filepath = (char*)malloc(sizeof(char) * (len + 1));
    
    [writablePath getCString:filepath maxLength:len + 1 encoding:[NSString defaultCStringEncoding]];
    
    return filepath;
}

+(char*)getFilePath
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *strName = LOG_FILE_NAME([[UIDevice currentDevice] model] ,[[UIDevice currentDevice] systemVersion], [[self class] fileNameTime]);
    
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:strName];
    
    NSUInteger len = [writablePath length];
    
    char *filepath = (char*)malloc(sizeof(char) * (len + 1));
    
    [writablePath getCString:filepath maxLength:len + 1 encoding:[NSString defaultCStringEncoding]];
    
    return filepath;
}

+(NSString *)fileNameTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    //用[NSDate date]可以获取系统当前时间
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    return currentDateStr;
}

-(NSString *)logFilePath
{
    return [NSString stringWithCString:filePath encoding:NSUTF8StringEncoding];
}

-(void)close
{
    fclose(_fp);
}

-(void)dealloc
{
    if (_fp) {
        fclose(_fp);
    }
}


@end

@implementation VVLiveDebugInfo

@end