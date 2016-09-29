//
//  HPLiveSession.m
//  LiveDemo
//
//  Created by hp on 16/6/21.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "HPLiveSession.h"
//#import "ShowMaster.h"
//#import "GPUImageCameraSource.h"
//#import "AudioController.h"
//#import "NSDictionary+Model.h"
//#import <YYModel.h>

#define NOW_TIME (CACurrentMediaTime() * 1000)  //获取当前时间

@interface HPLiveSession() <VVVideoEncoderDelegate, VVAudioEncoderDelegate, HPCameraSourceDelegate>
{
    NSString *_rtmpUrlStr;
    
    BOOL _isSendingFirstFrame;
    double timeRecord;
    
    dispatch_semaphore_t _timeStampSemaphoreForServer;
    dispatch_semaphore_t _timeStampSemaphoreForLocal;
    
    BOOL _canPush;
    
    //日志相关
    VVLiveDebugInfoManager *_logManager;
}
@end

@implementation HPLiveSession

-(id)initWithLiveSteamUrl:(NSString *)liveSteamUrlStr andVideoConfig:(VVLiveVideoConfiguration *)videoConfig andAudiConfig:(VVLiveAudioConfiguration *)audioConfig
{
    self = [super init];
    if (self) {
        
        _rtmpUrlStr = @"";
        _canPush = NO;
        
        self.rtmpSocket = [[VVLiveRtmpSocket alloc] initWithRtmpUrlStr:liveSteamUrlStr];
//        _rtmpSocket.delegate = self;
//
        self.videoEncoder = [[VVVideoEncoder alloc] initWithConfig:videoConfig];
        _videoEncoder.delegate = self;
//
////        self.audioEncoder = [[VVAudioEncoder alloc] init];
////        _audioEncoder.delegate = self;
//        
//        self.softAudioEncoder = [[VVAudioSoftEncoder alloc] initWithConfig:audioConfig];
//        _softAudioEncoder.delegate = self;
//        
        _isSendingFirstFrame = YES;
        _timeStampSemaphoreForServer = dispatch_semaphore_create(1);
        _timeStampSemaphoreForLocal = dispatch_semaphore_create(1);

//        _logManager = [[VVLiveDebugInfoManager alloc] init];
////        _logManager = [[VVLiveDebugInfoManager alloc] initWithFileName:[NSString stringWithFormat:@"%lu-live_%@", (unsigned long)roomId,@"audio_log"]];
        //init camera
        self.cameraSource = [[HPCameraSource alloc] init];
        _cameraSource.delegate = self;
    }
    return self;
}

-(id)initWithLiveSteamUrl:(NSString *)liveSteamUrlStr
{
    self = [self initWithLiveSteamUrl:liveSteamUrlStr andVideoConfig:[VVLiveVideoConfiguration defaultConfiguration] andAudiConfig:[VVLiveAudioConfiguration defaultConfiguration]];
    if (self) {
        
    }
    return self;
}

#pragma mark - socket control
-(void)start
{
    if (_rtmpSocket) [_rtmpSocket start];
    [_cameraSource startVideoCamera];
//    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC));
//    dispatch_after(when, dispatch_get_main_queue(), ^(void) {
//        [[AudioController sharedInstance] startCapture];
//    });
}

-(void)stop
{
//    [[AudioController sharedInstance] stopCapture];
    [_cameraSource stopVideoCamera];
    if (_rtmpSocket) [_rtmpSocket stop];
//    if (_softAudioEncoder) [_softAudioEncoder encoderStop];
//    [_logManager close];
}

-(void)pushStream
{
    _canPush = YES;
}

#pragma mark - audio & video encode
-(void)audioEncodeWithBufferList:(AudioBufferList)bufferList timeStamp:(uint64_t)time
{
    [_softAudioEncoder encodeBufferList:bufferList timeStamp:[self sessionTimeStampForLocal]];
}

-(void)videoEncodeWithImageBuffer:(CVImageBufferRef)imageBuffer
{
    if(_videoEncoder) [_videoEncoder encodeImageBuffer:imageBuffer timeStamp:[self sessionTimeStampForLocal]];
}

#pragma mark - audio & video complete delegate
-(void)audioEncodeComplete:(VVAudioEncodeFrame *)encodeFrame
{
    if (_rtmpSocket && _canPush) [_rtmpSocket sendFrame:encodeFrame];
}

-(void)videoEncodeComplete:(VVVideoEncodeFrame *)encodeFrame
{
    if (_rtmpSocket && _canPush) [_rtmpSocket sendFrame:encodeFrame];
}

#pragma mark - audio & video config info
-(VVLiveVideoConfiguration *)videoConfigure
{
    return _videoEncoder.currentVideoEncodeConfig;
}

-(VVLiveAudioConfiguration *)audioConfigure
{
    return _audioEncoder.currentAudioEncodeConfig;
}

#pragma mark - rtp delegate
-(void)connectResult:(BOOL)result
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(sessionConnectResult:)])
    {
        [self.delegate sessionConnectResult:result];
    }
}

#pragma mark - videoCamera

-(void)setShowLiveView:(UIView *)showLiveView
{
    _showLiveView = showLiveView;
    
    if (_cameraSource) {
        [_cameraSource setupOnView:_showLiveView];
    }

}

#pragma mark - 统计上报
/*
-(void)rtpReportUploadInfo:(NSString *)reportStr
{
    NSDictionary *reportDic = [NSDictionary dictionaryWithJSON:reportStr];
    
    [VVLiveStatics reportMediaUpload:[ShowMaster shared].createLiveModel.liveID zhuboid:[AccountMaster shared].userID a_send:[reportDic[@"audio"] longValue] a_req1:[reportDic[@"audioReq1"] intValue] a_req2:[reportDic[@"audioReq2"] intValue] a_req3:[reportDic[@"audioReq3"] intValue] v_send:[reportDic[@"video"] longValue] v_req1:[reportDic[@"videoReq1"] intValue] v_req2:[reportDic[@"videoReq2"] intValue] v_req3:[reportDic[@"videoReq3"] intValue] v_reject1:[reportDic[@"videoReject1"] longValue] v_reject2:[reportDic[@"videoReject2"] intValue] v_sendlost:[reportDic[@"videoSendLost"] intValue] ttl:[reportDic[@"ttl"] intValue]];

}

-(void)rtpReportConnInfo:(NSString *)reportStr
{
     NSDictionary *reportDic = [NSDictionary dictionaryWithJSON:reportStr];
    
    [VVLiveStatics reportConnectMediaResult:[ShowMaster shared].createLiveModel.liveID zhuboid:[AccountMaster shared].userID mediaIp:reportDic[@"mediaIP"] mediaPort:[reportDic[@"mediaPort"] intValue] proxyIp:reportDic[@"proxyIP"] proxyPort:[reportDic[@"proxyPort"] intValue] result:[reportDic[@"result"] intValue]];
}

-(void)rtpReportBwFullInfo:(NSString *)reportStr
{
     NSDictionary *reportDic = [NSDictionary dictionaryWithJSON:reportStr];
    [VVLiveStatics reportBandwidthFull:[ShowMaster shared].createLiveModel.liveID send:[reportDic[@"sendCount"] longValue] byte:[reportDic[@"sendByte"] longValue] lost:[reportDic[@"lostCount"] longValue] req:[reportDic[@"reqLostCount"] longValue] sendlost:[reportDic[@"sendReqLostCount"] longValue]  RejectRepair:[reportDic[@"rejectRepair"] longValue]];
}

-(void)rtpReportLiveStatus
{
    
    NSArray *encoderDelayArray = [NSArray arrayWithArray:[_videoEncoder encodeDelayDataArray]];
    NSArray *encoderFrameArray = [NSArray arrayWithArray:[_videoEncoder encodeFrameArray]];
    int audioFrameLost = (int)[_softAudioEncoder getDropPacketNum];
    int videoFrameLost = (int)[_videoEncoder getDropFrameNum];

    [VVLiveStatics reportLiveStatus:[ShowMaster shared].createLiveModel.liveID
                             userId:[AccountMaster shared].userID
                            mediaId:[ShowMaster shared].mediaID
                           serverIP:[ShowMaster shared].mediaServerIP
                        capturelost:encoderFrameArray
                    encodeLostFrame:videoFrameLost
                     encodeMaxDelay:(long)[[encoderDelayArray valueForKeyPath:@"@max.floatValue"] floatValue]
                 encodeAverageDelay:(long)[[encoderDelayArray valueForKeyPath:@"@avg.floatValue"] floatValue]
                   audioQueueLength:[_softAudioEncoder audioQueueSize]
                       captureWidth:[GPUImageCameraSource sharedInstance].cameraSize.width
                      captureHeight:[GPUImageCameraSource sharedInstance].cameraSize.height
                         videoWidth:_videoEncoder.currentVideoEncodeConfig.videoSize.width
                        videoHeight:_videoEncoder.currentVideoEncodeConfig.videoSize.height
                     audioFrameLost:audioFrameLost
                     aslProcessTime:0];
}

-(void)reportBitRate:(uint32_t)bitRate
{
    
    [VVLiveStatics reportAdjustBitRateStatus:[ShowMaster shared].createLiveModel.liveID userId:[AccountMaster shared].userID mediaId:[ShowMaster shared].mediaID bitRate:bitRate];
}

-(void)audioLog:(NSString *)logStr
{
    if(_logManager) [_logManager log:logStr];
}

-(void)uploadLogFile
{
    [[VVLiveProto sharedProto] uploadDebugFile:_logManager.logFilePath withParam:@{@"platform":@"ios"} toUrl:@"http://182.118.27.27/uploadfile/upload"];
}

*/

#pragma mark - timeStamp maker
-(uint64_t)sessionTimeStampForServer
{
    dispatch_semaphore_wait(_timeStampSemaphoreForServer, DISPATCH_TIME_FOREVER);
    double currentTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    dispatch_semaphore_signal(_timeStampSemaphoreForServer);
    return (uint64_t)currentTimeStamp;
}

-(uint64_t)sessionTimeStampForLocal
{
    dispatch_semaphore_wait(_timeStampSemaphoreForLocal, DISPATCH_TIME_FOREVER);
    uint64_t currentTimeStamp;
    if (_isSendingFirstFrame) {
        timeRecord = NOW_TIME;
        currentTimeStamp = 0;
        _isSendingFirstFrame = NO;
    }
    else
    {
        currentTimeStamp = NOW_TIME - timeRecord;
    }
    
    dispatch_semaphore_signal(_timeStampSemaphoreForLocal);
    return currentTimeStamp;
}

#pragma mark - other
-(void)dealloc
{
    
}
@end
