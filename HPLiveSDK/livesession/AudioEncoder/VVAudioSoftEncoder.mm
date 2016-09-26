//
//  VVAudioSoftEncoder.m
//  livesession
//
//  Created by hp on 16/8/13.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import "VVAudioSoftEncoder.h"
#import "AudioFrameEncoder.h"
#import "Queue.h"
#import "VVLiveDebugInfoManager.h"


@interface VVAudioSoftEncoder()
{
    CAudioFrameEncoder *_audioSoftEncoder;
    Queue *_audioEncoderQueue;
    
    //编码队列
    dispatch_queue_t _encodeQueue;
    
    dispatch_semaphore_t _dropPacketSemaphore;    //丢包记录信号量
}

-(void)clear;
-(int32_t)tryPop:(uint8_t *)encodeBuffer buffSize:(int)bufferSize timeOut:(int)timeOut pts:(int64_t*)pts;
-(void)pushData:(uint8_t *)data size:(int)size timestamp:(unsigned int)timestamp;

-(void)audioLog:(char *)logStr;
@end

// 回调函数的实现
void audioEncoderClear(void *delegate) {
    
    // 调用Objc的函数
    VVAudioSoftEncoder *encoder = (__bridge VVAudioSoftEncoder *)delegate;
    [encoder clear];
}

void audioEncoderPushAACData(void *delegate, uint8_t *data,int size,unsigned int timestamp) {
    
    // 调用Objc的函数
    VVAudioSoftEncoder *encoder = (__bridge VVAudioSoftEncoder *)delegate;
    [encoder pushData:data size:size timestamp:timestamp];
}

int32_t audioEncodertryPop(void *delegate, uint8_t *encodeBuffer, int bufferSize, int timeOut, int64_t *pts) {
    
    // 调用Objc的函数
    VVAudioSoftEncoder *encoder = (__bridge VVAudioSoftEncoder *)delegate;
    return [encoder tryPop:encodeBuffer buffSize:bufferSize timeOut:timeOut pts:pts];
    

}

void audioLogCallBack(void *delegate, char *logStr)
{
    // 调用Objc的函数
    VVAudioSoftEncoder *encoder = (__bridge VVAudioSoftEncoder *)delegate;
    [encoder audioLog:logStr];
    return;
}

void audioDropPacketCallBack(void *delegate)
{
    // 调用Objc的函数
    VVAudioSoftEncoder *encoder = (__bridge VVAudioSoftEncoder *)delegate;
    encoder.dropPacketNum ++;
    return;
    
}

@implementation VVAudioSoftEncoder

-(id)init
{
    self = [self initWithConfig:[VVLiveAudioConfiguration defaultConfiguration]];
    if (self) {
        
        
    }
    return self;
}

-(id)initWithConfig:(VVLiveAudioConfiguration *)config
{
    self = [super init];
    if (self) {
        __weak VVAudioSoftEncoder *w_self = self;
        
        _dropPacketNum = 0;
        //编码队列
        _encodeQueue = dispatch_queue_create("audioSoftEncodeQueue", nil);
        _dropPacketSemaphore = dispatch_semaphore_create(1);
        
        _currentAudioEncodeConfig = config;
        _audioEncoderQueue = new Queue;
        _audioEncoderQueue->m_delegate = (__bridge void *)w_self;
        _audioEncoderQueue->audioLogCallBack = audioLogCallBack;
        _audioEncoderQueue->audioDropPacketCallBack = audioDropPacketCallBack;
        
        _audioSoftEncoder = new CAudioFrameEncoder ;
        _audioSoftEncoder->Init(_currentAudioEncodeConfig.audioSampleRate, _currentAudioEncodeConfig.numberOfChannels, _currentAudioEncodeConfig.audioBitrate/1000, _currentAudioEncodeConfig.aacObjectType, (__bridge void *)w_self);
        _audioSoftEncoder->audioEncoderPushAACData = audioEncoderPushAACData;
        _audioSoftEncoder->audioEncodertryPop = audioEncodertryPop;
        _audioSoftEncoder->audioEncoderClear = audioEncoderClear;
        [self encoderStart];


    }
    return self;
}

#pragma mark - control
-(void)encodeBufferList:(AudioBufferList)bufferList timeStamp:(uint64_t)timeStamp
{
    dispatch_async(_encodeQueue, ^{
        @autoreleasepool {
            _audioEncoderQueue->push(bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize, timeStamp);
        }
    });
}

-(void)encoderStart
{
    _audioEncoderQueue->start();
    _audioSoftEncoder->start();
}

-(void)encoderStop
{
    _audioSoftEncoder->stop();
}

//获取队列长度
-(int32_t)audioQueueSize
{
    return _audioEncoderQueue->getQueueSize();
}

#pragma mark - call back
-(void)clear
{
    _audioEncoderQueue->clear();
    _audioEncoderQueue->finish();
}

-(int32_t)tryPop:(uint8_t *)encodeBuffer buffSize:(int)bufferSize timeOut:(int)timeOut pts:(int64_t*)pts
{
    return _audioEncoderQueue->trypop(encodeBuffer, bufferSize, timeOut, pts);
}

-(void)pushData:(uint8_t *)data size:(int)size timestamp:(unsigned int)timestamp
{
    VVAudioEncodeFrame *audioFrame = [[VVAudioEncodeFrame alloc] init];
    audioFrame.encodeData = [NSData dataWithBytes:data length:size];
    audioFrame.timeStamp = timestamp;
    char exeData[2];
    exeData[0] = _currentAudioEncodeConfig.asc[0];// 0x12;
    exeData[1] = _currentAudioEncodeConfig.asc[1];// 0x10;
    audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioEncodeComplete:)]) {
        [self.delegate audioEncodeComplete:audioFrame];
    }
}

-(void)audioLog:(char *)logStr
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioLog:)]) {
        [self.delegate audioLog:[NSString stringWithCString:logStr encoding:NSUTF8StringEncoding]];
    }
}

-(void)setDropPacketNum:(NSInteger)dropPacketNum
{
    dispatch_semaphore_wait(_dropPacketSemaphore, DISPATCH_TIME_FOREVER);
    _dropPacketNum = dropPacketNum;
    dispatch_semaphore_signal(_dropPacketSemaphore);
}

-(NSInteger)getDropPacketNum
{
    dispatch_semaphore_wait(_dropPacketSemaphore, DISPATCH_TIME_FOREVER);
    NSInteger tempNum;
    tempNum = _dropPacketNum;
    _dropPacketNum = 0;
    dispatch_semaphore_signal(_dropPacketSemaphore);
    return tempNum;
}

-(void)dealloc
{
    NSLog(@"audioSoftEncoder dealloc");
}


@end
