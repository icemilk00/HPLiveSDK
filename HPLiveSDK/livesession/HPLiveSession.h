//
//  HPLiveSession.h
//  LiveDemo
//
//  Created by hp on 16/6/21.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "livesession.h"


@protocol LiveSessionDelegate <NSObject>

-(void)sessionConnectResult:(BOOL)result;

@end

@interface HPLiveSession : NSObject

//推流
@property (nonatomic, strong) VVLiveRtpSocket *rtpSocket;

//视频编码器
@property (nonatomic, strong) VVVideoEncoder *videoEncoder;

//音频编码器
@property (nonatomic, strong) VVAudioEncoder *audioEncoder;         //硬编码器
@property (nonatomic, strong) VVAudioSoftEncoder *softAudioEncoder; //软编码器

//视频采集
@property (nonatomic, strong) HPCameraSource *cameraSource;

//音频采集

@property (nonatomic, assign) id <LiveSessionDelegate> delegate;


-(id)initWithLiveSteamUrl:(NSString *)liveSteamUrlStr;
-(id)initWithLiveSteamUrl:(NSString *)liveSteamUrlStr andVideoConfig:(VVLiveVideoConfiguration *)videoConfig andAudiConfig:(VVLiveAudioConfiguration *)audioConfig;

-(void)start;
-(void)stop;

-(void)pushStream;

-(void)audioEncodeWithBufferList:(AudioBufferList)bufferList timeStamp:(uint64_t)time;

-(void)videoEncodeWithImageBuffer:(CVImageBufferRef)imageBuffer timeStamp:(uint64_t)time;

-(VVLiveVideoConfiguration *)videoConfigure;
-(VVLiveAudioConfiguration *)audioConfigure;

-(void)audioLog:(NSString *)logStr;

-(void)setupCameraOnView:(UIView *)view;

@end
