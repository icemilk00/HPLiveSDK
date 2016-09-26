//
//  VVVideoEncoder.h
//  LiveDemo
//
//  Created by hp on 16/6/19.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "VVVideoEncodeFrame.h"
#import "VVLiveVideoConfiguration.h"


@class VVVideoConfigure;

@protocol VVVideoEncoderDelegate <NSObject>

-(void)videoEncodeComplete:(VVVideoEncodeFrame *)encodeFrame;
-(void)reportBitRate:(uint32_t)bitRate;

-(uint64_t)sessionTimeStampForLocal;


@end

@interface VVVideoEncoder : NSObject

@property (nonatomic, strong) VVLiveVideoConfiguration *currentVideoEncodeConfig;

@property (nonatomic, assign) BOOL isNeedSaveFlvFile;
-(void)saveDataForFlvFile;

-(id)initWithConfig:(VVLiveVideoConfiguration *)config;

-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp;
-(void)encodeImageBuffer:(CVImageBufferRef)imageBuffer timeStamp:(uint64_t)timeStamp;

-(void)changeVideoBitRate:(NSInteger)videoBitRate;         //修改码率
-(void)changeVideoFrameRate:(NSInteger)videoFrameRate;     //修改帧率
-(void)changeVideoBitRate:(NSInteger)videoBitRate andFrameRate:(NSInteger)frameRate;    //改变码率和帧率

-(NSString *)debugLogPath;
-(NSArray *)debugFlvPath;

-(NSArray *)encodeDelayDataArray;
-(NSArray *)encodeFrameArray;

@property (nonatomic, weak) id <VVVideoEncoderDelegate> delegate;

-(NSInteger)getDropFrameNum;
@end

