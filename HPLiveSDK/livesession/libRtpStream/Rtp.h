//
//  Rtp.h
//  libRtpStream
//
//  Created by hp on 16/6/24.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *RtpConnectSuccess = @"RtpConnectSuccess";
static NSString *RtpAdJustBitRate = @"RtpAdJustBitRate";
static NSString *RtpAdJustBitRateResult = @"RtpAdJustBitRateResult";    //调整码流结果

//统计回调
static NSString *RtpReportUploadInfo = @"RtpReportUploadInfo";
static NSString *RtpReportConnInfo = @"RtpReportConnInfo";
static NSString *RtpReportBwFullInfo = @"RtpReportBwFullInfo";

//typedef void(*ConnectCompleteCallBack)(bool abResult, uint16_t asPort);

@interface Rtp : NSObject

-(id)initWithConfigWithRoomId:(NSUInteger)roomId userId:(unsigned long long)userId mediaId:(NSUInteger)mediaId serverIP:(NSString *)serverIP minPort:(NSInteger)minPort maxPort:(NSInteger)maxPort  strToken:(NSString *)strToken strPcid:(NSString *)strPcid isAgent:(NSInteger)isAgent agentMediaIP:(NSString *)agentMediaIP agentMediaPort:(NSInteger)agentMediaPort;

-(void)configWithIsUseProxy:(BOOL)bUseProxy proxyIP:(NSString *)proxyIP minPort:(NSInteger)minPort maxPort:(NSInteger)maxPort;

-(void)start;
-(void)stop;

-(BOOL)putVideoData:(uint8_t *)data andLength:(uint32_t)length andTimeStamp:(unsigned int)timeStamp andIsKeyFrame:(bool)isKeyFrame;
-(BOOL)putAudioData:(uint8_t *)data andLength:(uint32_t)length andTimeStamp:(unsigned int)timeStamp;

@end


