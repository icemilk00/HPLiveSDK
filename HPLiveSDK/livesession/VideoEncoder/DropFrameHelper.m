//
//  DropFrameHelper.m
//  livesession
//
//  Created by hp on 16/8/30.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import "DropFrameHelper.h"

#define CURRENT_TIME ([[[NSDate alloc] init] timeIntervalSince1970] * 1000)
#define DEFAULT_SCROLL_WINDOW_LENGTH  1000

@interface DropFrameHelper()
{
    NSInteger m_iFrameRate;     //丢帧的控制帧率
    long m_beginTime;           //开始时间
    
    NSMutableArray *m_lstFrames;
    NSMutableArray *m_lostFrames;
    NSMutableArray *m_SelectedFrames;
    NSInteger frameIdCount;     //帧编号
    
    BOOL m_bUseTimerTask;       //是否启用定时器扫描
    NSInteger m_iScanFs;        //扫描频率
    
    NSInteger m_iScrollWindowLength;    //当前滑动窗口的长度
    
    BOOL m_bExcuterStarted;     //当前定时器是否在开始状态
    BOOL m_isStarted;           //当前的运行状态
    
    BOOL m_bLastFrameDropped;   //上一帧是否被丢了，如果丢了，则当前帧不丢，防止连续丢帧
}


@end

@implementation DropFrameHelper

-(id)initWithFrameRate:(NSInteger)fps useTimerTask:(BOOL)useTimerTask
{
    self = [super init];
    if (self) {
        
        m_iFrameRate = fps;
        m_iScrollWindowLength = DEFAULT_SCROLL_WINDOW_LENGTH;
        
        m_iScanFs = m_iFrameRate == 0 ? 0 : m_iScrollWindowLength / m_iFrameRate;
        
        m_bUseTimerTask = useTimerTask;
        
        m_bUseTimerTask = NO;
        m_bExcuterStarted = NO;
        m_bLastFrameDropped = NO;
        
        m_isStarted = NO;
        
    }
    return self;
}

-(void)start
{
    m_beginTime = CURRENT_TIME;
    m_lstFrames = [[NSMutableArray alloc] init];
    m_lostFrames = [[NSMutableArray alloc] init];
    m_SelectedFrames = [[NSMutableArray alloc] init];
    
    m_bLastFrameDropped = NO;
    
    if(m_bUseTimerTask){
//        executor = Executors.newScheduledThreadPool(1);
//        
//        executor.scheduleAtFixedRate(new SampleTimerTask(m_beginTime), 1000 + m_iScanFs,
//                                     m_iScanFs, TimeUnit.MILLISECONDS);
        
        m_bExcuterStarted = YES;
    }
    
     m_isStarted = YES;
}

-(void)stop
{
     m_isStarted = NO;
    
    if(m_bUseTimerTask){
//        executor.shutdownNow();
//        executor = null;
        m_bExcuterStarted = NO;
    }
    
//    writePushMsgToFile(m_lostFrames, 2);
    
    [m_lstFrames removeAllObjects];
    [m_lostFrames removeAllObjects];
    [m_SelectedFrames removeAllObjects];
    
    m_lstFrames = nil;
    m_lostFrames = nil;
    m_SelectedFrames = nil;
    
}

-(void)setFrameRate:(NSInteger)frameRate
{
    if(frameRate != 0){
        m_iFrameRate = frameRate;
        m_iScanFs = m_iScrollWindowLength / m_iFrameRate;
        [self restartExcutor];
    }
}

-(BOOL)isEncodeFrame
{
    
    if (m_isStarted == NO) {
        return YES;
    }
    
//    if(m_bUseTimerTask){
//        return [self isEncodeNextFrame];
//    }
    
    return [self isEncodeThisFrame];
}

-(BOOL)isEncodeThisFrame
{

    long nowTime = CURRENT_TIME;
    
    Frame *frame = [[Frame alloc] initWithFrameId:(++frameIdCount) arriveTime:nowTime timeDif:nowTime - m_beginTime];

    if(frame.timeDif / m_iScrollWindowLength < 1){
        // 第一个滑动窗口内不丢帧
        [m_lstFrames addObject:frame];
        return YES;
    }
    
    // 写日志
//    if(Math.floor((double)frame.timeDif / m_iScrollWindowLength) >= second){
//        writePushMsgToFile(m_lstFrames, 1);
//        second++;
//    }
    
    // 删除位于滑动窗口前的数据，使滑动窗口大小保持不变
    long timediff = frame.timeDif - m_iScrollWindowLength;
    while(m_lstFrames.count > 0 && ((Frame *)(m_lstFrames.firstObject)).timeDif < timediff){
        [m_lstFrames removeObjectAtIndex:0];
    }
    
    if(m_lstFrames.count < m_iFrameRate){
        if(m_bLastFrameDropped){
            m_bLastFrameDropped = NO;
        }
        [m_lstFrames addObject:frame];
        return YES;
    }else{
        if(m_bLastFrameDropped){
            [m_lstFrames addObject:frame];
            m_bLastFrameDropped = NO;
            return YES;
        }
//        [m_lostFrames addObject:frame];
        m_bLastFrameDropped = YES;
        return NO;
    }
}

-(BOOL)isEncodeNextFrame
{
    return NO;
}

-(void)restartExcutor
{
    if(!m_bUseTimerTask){
        return;
    }
    
    if(m_bExcuterStarted){
        [self stop ];
        [self start];
    }
}

@end


@implementation Frame

-(id)initWithFrameId:(NSInteger)frameId arriveTime:(long)arriveTime timeDif:(long)timeDif
{
    self = [super init];
    if (self) {
        self.frameId = frameId;
        self.arriveTime = arriveTime;
        self.timeDif = timeDif;
    }
    return self;
}

@end


