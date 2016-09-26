//
//  VVAudioSoftEncoder.h
//  livesession
//
//  Created by hp on 16/8/13.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VVLiveAudioConfiguration.h"
#import "VVAudioEncodeFrame.h"
#import "VVAudioEncoder.h"

@interface VVAudioSoftEncoder : NSObject

-(id)initWithConfig:(VVLiveAudioConfiguration *)config;
-(void)encodeBufferList:(AudioBufferList)bufferList timeStamp:(uint64_t)timeStamp;

-(void)encoderStart;
-(void)encoderStop;

-(int32_t)audioQueueSize;

@property (nonatomic, assign) NSInteger dropPacketNum;
-(NSInteger)getDropPacketNum;

@property (nonatomic, strong) VVLiveAudioConfiguration *currentAudioEncodeConfig;

@property (nonatomic, weak) id <VVAudioEncoderDelegate> delegate;
@end
