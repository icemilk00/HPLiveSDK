//
//  VVLivePacketer.m
//  livesession
//
//  Created by hp on 16/7/5.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import "VVLivePacketer.h"
#import <UIKit/UIKit.h>

#define FLV_FILE_NAME(devicename, osname, time, fileName)  [NSString stringWithFormat:@"%@-%@-%@-%@", devicename, osname, time, fileName]

#define kTagLength (4)
#define kAVCPacketHeaderSize  (5)
#define FLV_TAG_SIZE 11

/* FLV tag */
#define FLV_TAG_TYPE_AUDIO  ((uint8_t)0x08)
#define FLV_TAG_TYPE_VIDEO  ((uint8_t)0x09)
#define FLV_TAG_TYPE_META   ((uint8_t)0x12)

@implementation VVLivePacketer

#pragma mark - head
+(NSData *)flvVideoHeadsWithSps:(NSData *)sps pps:(NSData *)pps
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    [data appendData:[[self class] FLVHeadWithType:FlvFlagsTypeVideo]];
    [data appendData:[[self class] FLVBody_PreviousTagSize]];
    [data appendData:[[self class] FLVBodyWithVideoHeader:sps pps:pps]];
    
    return data;
}

+(NSData *)flvAudioHeadsWithAudioInfo:(NSData *)audioInfo
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    [data appendData:[[self class] FLVHeadWithType:FlvFlagsTypeAudio]];
    [data appendData:[[self class] FLVBody_PreviousTagSize]];
    [data appendData:[[self class] flvTagWithAudioHeader:audioInfo timeStamp:0]];
    
    return data;
}

+(NSData *)flvMixHeadsWithAudioInfo:(NSData *)audioInfo sps:(NSData *)sps pps:(NSData *)pps
{
    NSMutableData *data = [[NSMutableData alloc] init];
    [data appendData:[[self class] FLVHeadWithType:FlvFlagsTypeMix]];
    [data appendData:[[self class] FLVBody_PreviousTagSize]];
    [data appendData:[[self class] flvTagWithAudioHeader:audioInfo timeStamp:0]];
    [data appendData:[[self class] FLVBodyWithVideoHeader:sps pps:pps]];
    
    return data;
}


+(NSData *)FLVHeadWithType:(FlvFlagsType)type
{
    uint8_t flvheader[] = {0x46,0x4c,0x56,0x01,type,0x00,0x00,0x00,0x09};
    return [NSData dataWithBytes:flvheader length:9];
}

+(NSData *)FLVBody_PreviousTagSize
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    uint8_t prevTagSize[] = {0x00,0x00,0x00,0x00};
    [data appendBytes:prevTagSize length:4];
    
    return data;
}

+ (NSData*)FLVBodyWithVideoHeader:(NSData*)sps pps:(NSData*)pps
{
    NSMutableData *data = [[NSMutableData alloc] init];
    // 封装AVC sequence header
    const size_t kExtendSize = 11;
    size_t buffer_size = sps.length + pps.length + kExtendSize;
    
    // AVCPacket header size
    size_t body_size = kAVCPacketHeaderSize + buffer_size;
    size_t packet_size = body_size + FLV_TAG_SIZE;
    
    [data appendData:[[self class] FLVBody_FlvTagWithBodySize:body_size andTimeStamp:0 andFlvTagType:FLV_TAG_TYPE_VIDEO]];
    [data appendData:[[self class] FLVBody_VideoDataWithIsKeyframe:YES nalu:NO]];
    
    uint8_t configuration1[] = {0x01};
    [data appendBytes:&configuration1 length:1];
    [data appendBytes:&sps.bytes[1] length:1];
    [data appendBytes:&sps.bytes[2] length:1];
    [data appendBytes:&sps.bytes[3] length:1];
    uint8_t configuration2[] = {0xff};
    [data appendBytes:&configuration2 length:1];
    
    // sps
    uint8_t sps1[] = {0xe1};
    [data appendBytes:&sps1 length:1];
    uint8_t sps2[] = {(sps.length >> 8) & 0xff};
    [data appendBytes:&sps2 length:1];
    uint8_t sps3[] = {sps.length & 0xff};
    [data appendBytes:&sps3 length:1];
    [data appendBytes:sps.bytes length:sps.length];
    
    
    // pps
    uint8_t pps1[] = {0x01};
    [data appendBytes:&pps1 length:1];
    uint8_t pps2[] = {(pps.length >> 8) & 0xff};
    [data appendBytes:&pps2 length:1];
    uint8_t pps3[] = {pps.length & 0xff};
    [data appendBytes:&pps3 length:1];
    [data appendBytes:pps.bytes length:pps.length];
    
    uint32_t pre_size = htonl(packet_size);
    [data appendBytes:&pre_size length:sizeof(uint32_t)];
    
    return data;
}

+(NSData *)FLVBody_FlvTagWithBodySize:(size_t)body_size andTimeStamp:(uint32_t)timeStamp andFlvTagType:(uint8_t)type
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    uint8_t flvTag[] =  {type,
        (uint8_t)((body_size & 0x00FF0000U) >> 16),
        (uint8_t)((body_size & 0x0000FF00U) >> 8),
        (uint8_t)(body_size & 0x000000FFU),
        
        (uint8_t)((timeStamp & 0x00FF0000U) >> 16),
        (uint8_t)((timeStamp & 0x0000FF00U) >> 8),
        (uint8_t)(timeStamp & 0x000000FFU),
        
        (uint8_t)((timeStamp & 0xFF000000) >> 24),
        0x00,0x00,0x00};
    
    
    [data appendBytes:flvTag length:FLV_TAG_SIZE];
    
    return data;
}

+ (NSData*)FLVBody_VideoDataWithIsKeyframe:(BOOL)keyFrame nalu:(BOOL)nalu{
    uint8_t header[kAVCPacketHeaderSize] = { 0x00, 0x00, 0x00, 0x00, 0x00 };
    header[0]  = (keyFrame ? 0x10 : 0x20) | 0x07;
    header[1]  = nalu ? 0x01 : 0x00;    // 1: AVC NALU  0: AVC sequence header
    // 后三个字节为Composition time,在AVC中无用
    return [NSData dataWithBytes:header length:sizeof(header)];
}

+ (NSData*)flvTagWithAudioHeader:(NSData*)audioInfo timeStamp:(uint32_t)timeStamp{
    NSMutableData *data = [[NSMutableData alloc] init];
    const size_t kAACPacketHeaderSize = 2;
    
    size_t body_size = kAACPacketHeaderSize + audioInfo.length;
    size_t packet_size = body_size + FLV_TAG_SIZE;
    
    [data appendData:[[self class] FLVBody_FlvTagWithBodySize:body_size andTimeStamp:timeStamp andFlvTagType:FLV_TAG_TYPE_AUDIO]];
    
    uint8_t format[kAACPacketHeaderSize] = { 0xAF, 0x00 };
    [data appendBytes:format length:sizeof(format)];
    [data appendBytes:audioInfo.bytes length:audioInfo.length];
    
    uint32_t pre_size = htonl(packet_size);
    [data appendBytes:&pre_size length:sizeof(uint32_t)];
    
    return data;
}


#pragma mark - data
+(NSData *)videoDataWithNALUFrame:(VVVideoEncodeFrame *)videoFrame
{
    NSMutableData *data = [[NSMutableData alloc] init];
    
    uint32_t kAVCPacketSize = kAVCPacketHeaderSize + 4;
    
    size_t buffer_size = kAVCPacketSize + videoFrame.encodeData.length + FLV_TAG_SIZE;
    size_t packet_size = buffer_size + kTagLength;
    
    [data appendData:[[self class] FLVBody_FlvTagWithBodySize:(int32_t)videoFrame.encodeData.length + kAVCPacketSize andTimeStamp:videoFrame.timeStamp andFlvTagType:FLV_TAG_TYPE_VIDEO]];
    [data appendData:[[self class] FLVBody_VideoDataWithIsKeyframe:videoFrame.isKeyFrame nalu:true]];
    
    // write length
    size_t size = videoFrame.encodeData.length;
    uint8_t length[4] = { 0x00, 0x00, 0x00, 0x00 };
    length[0]  = (size >> 24) & 0xff;
    length[1]  = (size >> 16) & 0xff;
    length[2]  = (size >>  8) & 0xff;
    length[3]  = (size >>  0) & 0xff;
    [data appendBytes:length length:sizeof(length)];
    
    // write tag data
    [data appendData:videoFrame.encodeData];
    
    uint32_t pre_size = htonl(packet_size-4);
    [data appendBytes:&pre_size length:sizeof(uint32_t)];
    
    return data;
}

+(NSData *)audioDataWithNALUFrame:(VVAudioEncodeFrame *)audioFrame
{
    NSMutableData *data = [[NSMutableData alloc] init];
    const size_t kAACPacketHeaderSize = 2;
    
    size_t body_size = kAACPacketHeaderSize + audioFrame.encodeData.length;
    size_t packet_size = body_size + FLV_TAG_SIZE;
    
    [data appendData:[[self class] FLVBody_FlvTagWithBodySize:body_size andTimeStamp:audioFrame.timeStamp andFlvTagType:FLV_TAG_TYPE_AUDIO]];
    
    uint8_t format[kAACPacketHeaderSize] = { 0xAF, 0x01 };
    [data appendBytes:format length:sizeof(format)];
    [data appendBytes:audioFrame.encodeData.bytes length:audioFrame.encodeData.length];
    
    uint32_t pre_size = htonl(packet_size);
    [data appendBytes:&pre_size length:sizeof(uint32_t)];
    
    return data;
}


#pragma mark - path make
+(char*)GetFilePathByfileName:(char*)filename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *strName = FLV_FILE_NAME([[UIDevice currentDevice] model] ,[[UIDevice currentDevice] systemVersion], [[self class] fileNameTime], [NSString stringWithCString:filename encoding:NSUTF8StringEncoding]);
    
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:strName];
    
    NSUInteger len = [writablePath length];
    
    char *filepath = (char*)malloc(sizeof(char) * (len + 1));
    
    [writablePath getCString:filepath maxLength:len + 1 encoding:[NSString defaultCStringEncoding]];
    
    return filepath;
}

+(NSString *)fileNameTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    //用[NSDate date]可以获取系统当前时间
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    return currentDateStr;
}


@end
