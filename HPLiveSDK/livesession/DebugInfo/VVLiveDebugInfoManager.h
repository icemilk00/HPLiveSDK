//
//  VVLiveDebugInfoManager.h
//  livesession
//
//  Created by hp on 16/7/18.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class VVLiveDebugInfo;

@interface VVLiveDebugInfoManager : NSObject

//只写名字，不用路径
-(id)initWithFileName:(NSString *)fileName;
-(void)log:(NSString *)logStr;

-(NSString *)logFilePath;
-(void)close;

-(void)logFeedDataWithFrameIndex:(NSInteger)index;                  //喂给编码器时的数据打印
-(void)logOutDataWithFrameInfo:(VVLiveDebugInfo *)frameDebugInfo;   //编码器吐帧的时候的数据打印
-(void)logBitRateChangedFrom:(uint64_t)sourceBitRate toBitRate:(uint64_t)destBitRate FrameRateChangedFrom:(uint64_t)sourceFrameRate toFrameRate:(uint64_t)destFrameRate;            //改变码率和帧率时的数据打印

@end

@interface VVLiveDebugInfo: NSObject

//@property (nonatomic, copy) NSString *liveId;                           //流id
//@property (nonatomic, copy) NSString *liveUrl;                          //流地址

@property (nonatomic, assign) NSInteger frameCount;                     //帧编号
@property (nonatomic, assign) NSInteger frameType;                     //帧类型 I =1, P = 0
@property (nonatomic, assign) NSUInteger length;                        //帧大小
@property (nonatomic, assign) uint64_t frameTimeStamp;                  //帧时间戳
@property (nonatomic, assign) uint64_t currentTime;                     //当前时间
//@property (nonatomic, assign) uint64_t inSecond;                        //属于第几秒
@property (nonatomic, assign) NSUInteger videoBitRate;                  //码率
@property (nonatomic, assign) NSUInteger videoFrameRate;                //帧率

@end