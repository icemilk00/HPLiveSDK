//
//  VVLivePacketer.h
//  livesession
//
//  Created by hp on 16/7/5.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VVVideoEncodeFrame.h"
#import "VVAudioEncodeFrame.h"


typedef enum
{
    FlvFlagsTypeVideo = 0x01,
    FlvFlagsTypeAudio = 0x04,
    FlvFlagsTypeMix = 0x05
    
}FlvFlagsType;


@interface VVLivePacketer : NSObject

+(char*)GetFilePathByfileName:(char*)filename;

+(NSData *)flvVideoHeadsWithSps:(NSData *)sps pps:(NSData *)pps;
+(NSData *)flvAudioHeadsWithAudioInfo:(NSData *)audioInfo;
+(NSData *)flvMixHeadsWithAudioInfo:(NSData *)audioInfo sps:(NSData *)sps pps:(NSData *)pps;

+(NSData *)videoDataWithNALUFrame:(VVVideoEncodeFrame *)videoFrame;
+(NSData *)audioDataWithNALUFrame:(VVAudioEncodeFrame *)audioFrame;
@end
