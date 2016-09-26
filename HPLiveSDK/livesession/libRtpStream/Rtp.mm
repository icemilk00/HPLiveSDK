//
//  Rtp.m
//  libRtpStream
//
//  Created by hp on 16/6/24.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import "Rtp.h"
//#import "RtpProxy.h"

//#import "EncodeCallback.h"
//#import "ConnectRoomCallback.h"

#pragma mark -- AVEncodeCallback

/*
class AVEncodeCallback : public EncodeCallback{
public:
    void AdJustBitRate(int percent);
    void ReportStat(char* apStatString);
};

void AVEncodeCallback::AdJustBitRate(int percent)
{
    float f_percent = percent/100.0;
    [[NSNotificationCenter defaultCenter] postNotificationName:RtpAdJustBitRate object:@{@"percent":@(f_percent)}];
}

void AVEncodeCallback::ReportStat(char* apStatString)
{
    NSLog(@"ReportStat:%@", [NSString stringWithCString:apStatString encoding:NSUTF8StringEncoding]);
}

#pragma mark -- RtpConnectCallback
class RtpConnectCallback : public ConnectRoomCallback{
public:
    void NotifyJoinResult(bool abResult, uint16_t asPort);
    void ReportUploadInfo(const char* strUploadInfo);
    void ReportConnInfo(const char* strConnInfo);
    void ReportBwFullInfo(const char* strBwFullInfo);
};

void RtpConnectCallback::NotifyJoinResult(bool abResult, uint16_t asPort)
{
    RtpProxy::getInstance()->startSpeak();
    [[NSNotificationCenter defaultCenter] postNotificationName:RtpConnectSuccess object:@{@"ConnectResult":@(abResult),
                                                                                          @"ConnectPort":@(asPort)}];
}

void RtpConnectCallback::ReportUploadInfo(const char* strUploadInfo)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RtpReportUploadInfo object:@{@"ReportUploadInfo":[NSString stringWithCString:strUploadInfo encoding:NSUTF8StringEncoding]}];
//    "{\"audio\":%u,\"audioReq1\":%u,\"audioReq2\":%u,\"audioReq3\":%u,\"video\":%u,\"videoReq1\":%u,\"videoReq2\":%u,\"videoReq3\":%u,\"videoReject1\":%u,\"videoReject2\":%u,\"videoSendLost\":%u,\"ttl\":%u}"
}

void RtpConnectCallback::ReportConnInfo(const char* strConnInfo)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RtpReportConnInfo object:@{@"ReportConnInfo":[NSString stringWithCString:strConnInfo encoding:NSUTF8StringEncoding]}];
//    {"mediaIP":"","mediaPort":2,"proxyIP":"","proxyPort":2,"result":2}
}

void RtpConnectCallback::ReportBwFullInfo(const char* strBwFullInfo)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RtpReportBwFullInfo object:@{@"ReportBwFullInfo":[NSString stringWithCString:strBwFullInfo encoding:NSUTF8StringEncoding]}];
//    "{\"sendCount\":%u,\"sendByte\":%u,\"lostCount\":%u,\"reqLostCount\":%u,\"sendReqLostCount\":%u,\"rejectRepair\":%u}
}
*/

#pragma mark - rtp class

@interface Rtp()
{
//    AVEncodeCallback *encodeCallBack;
//    RtpConnectCallback *connectCallBack;
    
}
@end

@implementation Rtp

-(id)initWithConfigWithRoomId:(NSUInteger)roomId userId:(unsigned long long)userId mediaId:(NSUInteger)mediaId serverIP:(NSString *)serverIP minPort:(NSInteger)minPort maxPort:(NSInteger)maxPort  strToken:(NSString *)strToken strPcid:(NSString *)strPcid isAgent:(NSInteger)isAgent agentMediaIP:(NSString *)agentMediaIP agentMediaPort:(NSInteger)agentMediaPort
{
    self = [super init];
    if (self) {
//        RtpProxy::getInstance()->init((uint32_t)roomId, userId, (uint32_t)mediaId, [serverIP cStringUsingEncoding:NSUTF8StringEncoding], minPort, maxPort ,[strToken cStringUsingEncoding:NSUTF8StringEncoding] ,[strPcid cStringUsingEncoding:NSUTF8StringEncoding]);
//        RtpProxy::getInstance()->setProxy(isAgent, [agentMediaIP cStringUsingEncoding:NSUTF8StringEncoding], agentMediaPort, agentMediaPort);
//        encodeCallBack = new AVEncodeCallback;
//        RtpProxy::getInstance()->setEncodeCallback(encodeCallBack);
//        connectCallBack = new RtpConnectCallback;
//        RtpProxy::getInstance()->setConnectCallback(connectCallBack);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCanAdjustBitRate:) name:RtpAdJustBitRateResult object:nil];
        
    }
    return self;
}

-(void)configWithIsUseProxy:(BOOL)bUseProxy proxyIP:(NSString *)proxyIP minPort:(NSInteger)minPort maxPort:(NSInteger)maxPort
{
//    RtpProxy::getInstance()->setProxy(bUseProxy, [proxyIP cStringUsingEncoding:NSUTF8StringEncoding], minPort, maxPort);
}

-(void)start
{
//    RtpProxy::getInstance()->start();
    
}

-(void)stop
{
//    RtpProxy::getInstance()->stop();
}

-(BOOL)putVideoData:(uint8_t *)data andLength:(uint32_t)length andTimeStamp:(unsigned int)timeStamp andIsKeyFrame:(bool)isKeyFrame
{
//    return RtpProxy::getInstance()->PutVideoData(data, length, timeStamp,isKeyFrame);
    return NO;
}

-(BOOL)putAudioData:(uint8_t *)data andLength:(uint32_t)length andTimeStamp:(unsigned int)timeStamp
{
//    return RtpProxy::getInstance()->PutAudioData(data, length, timeStamp);
    return NO;
}

-(void)setCanAdjustBitRate:(NSNotification *)noti
{
    BOOL canAdjust = [noti.object boolValue];
//    RtpProxy::getInstance()->setAdjustBitrate(canAdjust);

}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    RtpProxy::getInstance()->stop();
}

@end




