//
//  VVLiveRtmpSocket.h
//  LiveDemo
//
//  Created by hp on 16/6/20.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VVEncodeFrame.h"

@protocol RtpSocketDelegate <NSObject>

-(void)connectResult:(BOOL)result;

-(void)rtpReportUploadInfo:(NSString *)reportStr;
-(void)rtpReportConnInfo:(NSString *)reportStr;
-(void)rtpReportBwFullInfo:(NSString *)reportStr;

@end

@interface VVLiveRtpSocket : NSObject

-(id)initWithoomId:(NSUInteger)roomId userId:(unsigned long long)userId mediaId:(NSUInteger)mediaId serverIP:(NSString *)serverIP minPort:(NSInteger)minPort maxPort:(NSInteger)maxPort strToken:(NSString *)strToken strPcid:(NSString *)strPcid isAgent:(NSInteger)isAgent agentMediaIP:(NSString *)agentMediaIP agentMediaPort:(NSInteger)agentMediaPort;

-(void)start;
-(void)stop;
-(void)sendFrame:(VVEncodeFrame *)frame;

@property (nonatomic, weak) id <RtpSocketDelegate> delegate;
@end
