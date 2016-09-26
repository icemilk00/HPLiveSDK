//
//  VVAudioEncoder.h
//  LiveDemo
//
//  Created by hp on 16/6/17.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "VVAudioEncodeFrame.h"
#import "VVLiveAudioConfiguration.h"


@protocol VVAudioEncoderDelegate <NSObject>

-(void)audioEncodeComplete:(VVAudioEncodeFrame *)encodeFrame;

-(uint64_t)sessionTimeStampForLocal;

-(void)audioLog:(NSString *)logStr;

@end


@interface VVAudioEncoder : NSObject

@property (nonatomic, strong) VVLiveAudioConfiguration *currentAudioEncodeConfig;

@property (nonatomic, assign) BOOL isNeedSaveFlvFile;
-(id)initWithConfig:(VVLiveAudioConfiguration *)config;

-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp;
-(void)encodeBufferList:(AudioBufferList)bufferList timeStamp:(uint64_t)timeStamp;

@property (nonatomic, weak) id <VVAudioEncoderDelegate> delegate;
@end
