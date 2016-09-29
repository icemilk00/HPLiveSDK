//
//  VVVideoEncoder.m
//  LiveDemo
//
//  Created by hp on 16/6/19.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVVideoEncoder.h"
#import "VVLiveVideoConfiguration.h"
#import "VVLivePacketer.h"
#import "VVLiveDebugInfoManager.h"
#import "Rtp.h"
#import "DropFrameHelper.h"

//#define VE_DEBUG

#ifdef VE_DEBUG
#define VELog(...) NSLog(__VA_ARGS__)

#else
#define VELog(...)

#endif

@interface VVVideoEncoder()
{
    BOOL _isBackGround;
    
    NSUInteger _currentBitRate;
    NSUInteger _currentMaxBitRate;
    NSUInteger _currentFrameRate;
    
    VTCompressionSessionRef _videoCompressionSession;
    
    int frameCount;
    
    NSData *sps;
    NSData *pps;
    
    //用于本地保存视频flv参数
    char *path;
    FILE *fp;
    NSMutableArray *_flvPathArray;
    BOOL _isSetupFlvHead;
    //用于本地写日志
    VVLiveDebugInfoManager *_debugManager;
    
    //编码队列
    dispatch_queue_t _encodeQueue;
    
    //用于统计上报的一些参数
    dispatch_semaphore_t _maxDelaySemaphore;    //编码延迟数组信号量
    NSMutableArray *_encodeDelayArray;          //编码延迟数组
    dispatch_semaphore_t _frameSemaphore;       //采集的帧数数组信号量
    NSMutableArray *_encodeFrameArray;          //采集的帧数数组
    long long _beginFlagTime;
    int _beginFrameCount;
    dispatch_semaphore_t _dropFrameSemaphore;    //总丢包信号量
    int _dropFrameNum;                  //总丢包数量
    int _dropFrameNumForSeconds;        //每秒丢包数量
    long _currentSecond;                //当前秒数
    
    DropFrameHelper *_dropFrameHelper;
}
@end


@implementation VVVideoEncoder

-(id)initWithConfig:(VVLiveVideoConfiguration *)config
{
    self = [super init];
    if (self) {

        frameCount = 0;
        _currentSecond = 0;
        _isBackGround = NO;
        _currentVideoEncodeConfig = config;

        _currentBitRate = _currentVideoEncodeConfig.videoBitRate;
        _currentMaxBitRate = _currentVideoEncodeConfig.videoMaxBitRate;
        _currentFrameRate = _currentVideoEncodeConfig.videoEncodeFrameRate;
        
        _encodeQueue = dispatch_queue_create("videoEncodeQueue", DISPATCH_QUEUE_SERIAL);
        _maxDelaySemaphore = dispatch_semaphore_create(1);
        _encodeDelayArray = [[NSMutableArray alloc] init];
        _frameSemaphore = dispatch_semaphore_create(1);
        _encodeFrameArray = [[NSMutableArray alloc] init];
        _dropFrameSemaphore = dispatch_semaphore_create(1);
        _dropFrameNum = 0;
        
        _dropFrameHelper = [[DropFrameHelper alloc] initWithFrameRate:_currentFrameRate useTimerTask:NO];
        [_dropFrameHelper start];
        
#ifdef DEBUG
        _isSetupFlvHead = NO;
        _isNeedSaveFlvFile = NO;
        _flvPathArray = [[NSMutableArray alloc] init];
        if(_isNeedSaveFlvFile) [self initForFilePath];
        _debugManager = [[VVLiveDebugInfoManager alloc] init];
#endif
        
        [self createCompressionSession];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(RtpAdJustBitRate:) name:RtpAdJustBitRate object:nil];
        
    }
    return self;
}

- (void)initForFilePath
{
    path = [VVLivePacketer GetFilePathByfileName:[[NSString stringWithFormat:@"%@_%@.flv", @(_currentBitRate/1024), @(_currentFrameRate)] cStringUsingEncoding:NSUTF8StringEncoding]];
    [_flvPathArray addObject:[NSString stringWithCString:path encoding:NSUTF8StringEncoding]];
    self->fp = fopen(path,"wb");
}

-(void)createCompressionSession
{
    dispatch_async(_encodeQueue, ^{

        [self cleanCompressionSession];
        VELog(@"createCompressionSession begin ~~~~~~~~~~~~~~~~");
        OSStatus status =  VTCompressionSessionCreate(NULL, _currentVideoEncodeConfig.videoSize.width, _currentVideoEncodeConfig.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, compressionOutputCallback, (__bridge void * _Nullable)(self), &_videoCompressionSession);
        
        if (status != noErr)
        {
            return;
        }
        
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval,(__bridge CFTypeRef)@(_currentVideoEncodeConfig.gop * _currentFrameRate)); //设置gop~1秒
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(_currentFrameRate));

        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(_currentBitRate));
        //设置后画质变清楚
        NSArray *limit = @[@(_currentMaxBitRate/8),@(1)];
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
        //是否实时编码
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanFalse);
        //指定编码流的配置和水平设为自动
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
        //是否允许帧重新排序，生成B帧相关
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_Quality, (__bridge CFTypeRef)@(_currentVideoEncodeConfig.quality));
        
        //编码H264的压缩方式，有CAVLC 和 CABAC ，这里选CABAC，CABAC质量高
        //CAVLC ：基于上下文的自适应可变长编码
        //CABAC ：基于上下文的自适应二进制算术编码
        //通常来说CABAC被认为比CAVLC效率高5%-15%。 这意味着，CABAC应该在码率低5-15%，的情况下，提供同等的，或者更高的视频质量
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
        VTCompressionSessionPrepareToEncodeFrames(_videoCompressionSession);
        VELog(@"createCompressionSession end ~~~~~~~~~~~~~~~~~~~~~~~\n");
//    CFStringRef output = nil;
//    VTSessionCopyProperty(_videoCompressionSession, kVTCompressionPropertyKey_ProfileLevel, kCFAllocatorDefault, &output);
//    NSLog(@"OUTPUT = %@", output);
    });
}

-(void)encodeImageBuffer:(CVImageBufferRef)imageBuffer timeStamp:(uint64_t)timeStamp
{
    dispatch_async(_encodeQueue, ^{
        @autoreleasepool {
            if(_isBackGround) return;
            
            BOOL isEncode = [_dropFrameHelper isEncodeFrame];
            if (!isEncode) {
                dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_FOREVER);
                _dropFrameNum ++;
                dispatch_semaphore_signal(_frameSemaphore);
                _dropFrameNumForSeconds ++;
                return;
            }
            
            frameCount++;
            
            CMTime presentationTimeStamp = CMTimeMake(frameCount, (int)_currentVideoEncodeConfig.videoFrameRate);
            VTEncodeInfoFlags flags;
            
            if (timeStamp - _beginFlagTime >= 1000) {
                dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_FOREVER);
                _currentSecond ++;
                [_encodeFrameArray addObject:@{@"capture":@(frameCount - _beginFrameCount),@"lost":@(_dropFrameNumForSeconds),@"second":@(_currentSecond)}];
                _beginFlagTime  = timeStamp;
                _beginFrameCount = frameCount;
                _dropFrameNumForSeconds = 0;
                dispatch_semaphore_signal(_frameSemaphore);
            }
            
            if(_debugManager) [_debugManager logFeedDataWithFrameIndex:frameCount];
            VELog(@"VTCompressionSessionEncodeFrame begin ");
            VTCompressionSessionEncodeFrame(_videoCompressionSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL,(__bridge_retained void * _Nullable)(@{@"timeStamp":@(timeStamp),@"frameCount":@(frameCount)}), &flags);
            VELog(@"VTCompressionSessionEncodeFrame end ");
        }
        
    });
}

-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp
{
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    [self encodeImageBuffer:imageBuffer timeStamp:timeStamp];

}

static void compressionOutputCallback(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    
    if (status != noErr) return;
    if (!sampleBuffer)   return;
    if (!CMSampleBufferDataIsReady(sampleBuffer)) return;

    VVVideoEncoder *videoEncoder = (__bridge VVVideoEncoder *)(outputCallbackRefCon);
    NSDictionary *tempSourceFrameRefCon = (__bridge_transfer NSDictionary*)sourceFrameRefCon;
    
    BOOL keyFrame = !CFDictionaryContainsKey(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), kCMSampleAttachmentKey_NotSync);
//    uint64_t timeStamp = [((__bridge_transfer NSNumber*)sourceFrameRefCon) longLongValue];
    uint64_t timeStamp = [tempSourceFrameRefCon[@"timeStamp"] longLongValue];
    
    //编码延迟
    int encoderDelay = [[NSDate date] timeIntervalSince1970] * 1000 - timeStamp;
    dispatch_semaphore_wait(videoEncoder->_maxDelaySemaphore, DISPATCH_TIME_FOREVER);
    [videoEncoder->_encodeDelayArray addObject:@(encoderDelay)];
    dispatch_semaphore_signal(videoEncoder->_maxDelaySemaphore);

    if (keyFrame) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        status =CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (status == noErr) {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (status == noErr)
            {
                videoEncoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                videoEncoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
            }
        }
        
        if (videoEncoder->_isNeedSaveFlvFile ) {
            if (videoEncoder->_isSetupFlvHead == NO) {
                videoEncoder->_isSetupFlvHead = YES;
                NSData *headData = [VVLivePacketer flvVideoHeadsWithSps:videoEncoder->sps pps:videoEncoder->pps];
                fwrite(headData.bytes, 1,headData.length,videoEncoder->fp);
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    status = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (status == noErr) {
        size_t buffOffset = 0;
        static const int AVCCHeaderLength = 4;
        NSMutableData *data = [[NSMutableData alloc] init];
    
        while (buffOffset < totalLength - AVCCHeaderLength) {
        
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + buffOffset, AVCCHeaderLength);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
        
            NSData *NALUdata = [[NSData alloc] initWithBytes:(dataPointer + buffOffset + AVCCHeaderLength) length:NALUnitLength];
            
//            if(keyFrame){
//                uint8_t header[] = {0x00,0x00,0x00,0x01};
//                [data appendBytes:header length:4];
//            }else{
//                uint8_t header[] = {0x00,0x00,0x00,0x01};
//                [data appendBytes:header length:4];
//            }
            
            [data appendData:NALUdata];
            
            buffOffset += AVCCHeaderLength + NALUnitLength;
            
            if (videoEncoder->_isNeedSaveFlvFile ) {
                if (videoEncoder->_isSetupFlvHead == YES) {
                    
                    VVVideoEncodeFrame *videoFrame = [[VVVideoEncodeFrame alloc] init];
                    videoFrame.timeStamp = [videoEncoder->_delegate sessionTimeStampForLocal];
                    videoFrame.encodeData = NALUdata;
                    videoFrame.sps = videoEncoder->sps;
                    videoFrame.pps = videoEncoder->pps;
                    videoFrame.isKeyFrame = keyFrame;
                    
                    NSData *videoData = [VVLivePacketer videoDataWithNALUFrame:videoFrame];
                    fwrite(videoData.bytes, 1,videoData.length,videoEncoder->fp);
                }
            }
        }
        
        VVVideoEncodeFrame *videoFrame = [[VVVideoEncodeFrame alloc] init];
        videoFrame.timeStamp = timeStamp;
        videoFrame.encodeData = [[NSData alloc] initWithBytes:data.bytes length:data.length];
        videoFrame.sps = videoEncoder->sps;
        videoFrame.pps = videoEncoder->pps;
        videoFrame.isKeyFrame = keyFrame;
        
        //打印日志
        VVLiveDebugInfo *debugInfo = [[VVLiveDebugInfo alloc] init];
        debugInfo.frameCount = [tempSourceFrameRefCon[@"frameCount"] integerValue];
        debugInfo.frameType = videoFrame.isKeyFrame == YES ? 1 : 0;
        debugInfo.length = videoFrame.encodeData.length;
        debugInfo.frameTimeStamp = videoFrame.timeStamp;
        debugInfo.currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
        debugInfo.videoBitRate = videoEncoder->_currentBitRate;
        debugInfo.videoFrameRate = videoEncoder->_currentFrameRate;
        if(videoEncoder->_debugManager) [videoEncoder->_debugManager logOutDataWithFrameInfo:debugInfo];
        
        if (videoEncoder->_delegate && [videoEncoder->_delegate respondsToSelector:@selector(videoEncodeComplete:)]) {
            [videoEncoder->_delegate videoEncodeComplete:videoFrame];
        }
    }
}

#pragma mark - 动态切换码率帧率

//改变码率
- (void)changeVideoBitRate:(NSInteger)videoBitRate{
    if(_isBackGround) return;
    _currentBitRate = videoBitRate;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(reportBitRate:)]) {
        [self.delegate reportBitRate:_currentBitRate];
    }
    VELog(@"change bit rate ！！！！！！！！！！！！！！！！！！！\n\n");
    [self createCompressionSession];
}

//改变帧率
- (void)changeVideoFrameRate:(NSInteger)videoFrameRate{
    if(_isBackGround) return;
    _currentFrameRate = videoFrameRate;
    if (_dropFrameHelper) {
        [_dropFrameHelper setFrameRate:_currentFrameRate];
    }
    
    [self createCompressionSession];
}

//改变码率和帧率
-(void)changeVideoBitRate:(NSInteger)videoBitRate andFrameRate:(NSInteger)frameRate
{
    if(_isBackGround) return;
    if (_debugManager) [_debugManager logBitRateChangedFrom:_currentBitRate toBitRate:videoBitRate FrameRateChangedFrom:_currentFrameRate toFrameRate:frameRate];

    _currentBitRate = videoBitRate;
    _currentFrameRate = frameRate;
    
    if (_dropFrameHelper) {
        [_dropFrameHelper setFrameRate:_currentFrameRate];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(reportBitRate:)]) {
        [self.delegate reportBitRate:_currentBitRate];
    }

    [self reConfigFlvSave];
    
    [self createCompressionSession];
}

//接受改变码率&帧率的消息
-(void)RtpAdJustBitRate:(NSNotification *)noti
{
    float f_percent = [noti.object[@"percent"] floatValue];
    
    NSUInteger afterAdjustBitRate = (NSUInteger)(_currentVideoEncodeConfig.videoBitRate * f_percent);
    NSUInteger afterAdjustFrameRate = (NSUInteger)(_currentVideoEncodeConfig.videoEncodeFrameRate * f_percent);
    
    if (afterAdjustBitRate >= _currentVideoEncodeConfig.videoMinBitRate && afterAdjustFrameRate >= _currentVideoEncodeConfig.videoMinFrameRate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RtpAdJustBitRateResult object:@(YES)];
        _currentMaxBitRate = _currentVideoEncodeConfig.videoMaxBitRate * f_percent;
        [self changeVideoBitRate:afterAdjustBitRate andFrameRate:afterAdjustFrameRate];
        return;
    }
    
    if (afterAdjustBitRate >= _currentVideoEncodeConfig.videoMinBitRate && afterAdjustFrameRate < _currentVideoEncodeConfig.videoMinFrameRate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RtpAdJustBitRateResult object:@(YES)];
        _currentMaxBitRate = _currentVideoEncodeConfig.videoMaxBitRate * f_percent;
        [self changeVideoBitRate:afterAdjustBitRate andFrameRate:_currentVideoEncodeConfig.videoMinFrameRate];
        return;
    }
    
    if (afterAdjustBitRate < _currentVideoEncodeConfig.videoMinBitRate && afterAdjustFrameRate >= _currentVideoEncodeConfig.videoMinFrameRate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RtpAdJustBitRateResult object:@(NO)];
        [self changeVideoBitRate:_currentVideoEncodeConfig.videoMinBitRate andFrameRate:afterAdjustFrameRate];
        return;
    }
    
    if (afterAdjustBitRate < _currentVideoEncodeConfig.videoMinBitRate && afterAdjustFrameRate < _currentVideoEncodeConfig.videoMinFrameRate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RtpAdJustBitRateResult object:@(NO)];
        [self changeVideoBitRate:_currentVideoEncodeConfig.videoMinBitRate andFrameRate:_currentVideoEncodeConfig.videoMinFrameRate];
        return;
    }

}

-(void)reConfigFlvSave
{
    if(_isNeedSaveFlvFile){
        if (fp) {
            fclose(fp);
        }
        _isSetupFlvHead = NO;
        [self initForFilePath];
    }
}

#pragma mark -- NSNotification
- (void)willEnterBackground:(NSNotification*)notification{
    _isBackGround = YES;
}

-(void)willEnterForeground:(NSNotification *)notifi
{
    if(_isBackGround == YES)
    {
        _isBackGround = NO;
        [self createCompressionSession];
    }
}

-(void)cleanCompressionSession
{
    if(_videoCompressionSession != NULL)
    {
        VTCompressionSessionCompleteFrames(_videoCompressionSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_videoCompressionSession);
        CFRelease(_videoCompressionSession);
        _videoCompressionSession = NULL;
    }
}

-(NSString *)debugLogPath
{
    if (_debugManager) {
        return [_debugManager logFilePath];
    }
    return @"";
}

-(NSArray *)debugFlvPath
{
    return _flvPathArray;
}

#pragma mark - 统计用参数
-(NSArray *)encodeDelayDataArray
{
    dispatch_semaphore_wait(_maxDelaySemaphore, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [NSArray arrayWithArray:_encodeDelayArray];
    [_encodeDelayArray removeAllObjects];
    dispatch_semaphore_signal(_maxDelaySemaphore);
    return tempArray;
}

-(NSArray *)encodeFrameArray
{
    dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_FOREVER);
    NSArray *tempArray = [NSArray arrayWithArray:_encodeFrameArray];
    [_encodeFrameArray removeAllObjects];
    dispatch_semaphore_signal(_frameSemaphore);
    return tempArray;
}

#pragma mark - 
-(NSInteger)getDropFrameNum
{
    dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_FOREVER);
    NSInteger tempNum;
    tempNum = _dropFrameNum ;
    _dropFrameNum = 0;
    dispatch_semaphore_signal(_frameSemaphore);
    return tempNum;
}

#pragma mark - dealloc
-(void)dealloc
{
    VELog(@"videoEncoder dealloc");
    [self cleanCompressionSession];
    [_dropFrameHelper stop];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (fp) {
        fclose(fp);
    }
}

@end
