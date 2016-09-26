//
//  VVLiveRtmpSocket.m
//  LiveDemo
//
//  Created by hp on 16/6/20.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVLiveRtpSocket.h"
#import "VVVideoEncodeFrame.h"
#import "VVAudioEncodeFrame.h"
#import "Rtp.h"

#define RTP_RECEIVE_TIMEOUT   2

@interface VVLiveRtpSocket()
{
    Rtp *_rtp;
    
    BOOL _hasSendFirstVideoFrame;
    BOOL _hasSendFirstAudioFrame;

    BOOL _isSending;
    BOOL _isConnected;
    BOOL _isConnecting;
    BOOL _isReconnecting;
    
    dispatch_semaphore_t _frameSortSemaphore;
}

@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, strong) NSMutableArray *frameBuffer;
@property (nonatomic, strong) NSMutableArray *sortFrameBuffer;

@property (nonatomic, strong) NSString *rtmpUrlStrl;

@end

@implementation VVLiveRtpSocket

-(id)initWithoomId:(NSUInteger)roomId userId:(unsigned long long)userId mediaId:(NSUInteger)mediaId serverIP:(NSString *)serverIP minPort:(NSInteger)minPort maxPort:(NSInteger)maxPort strToken:(NSString *)strToken strPcid:(NSString *)strPcid isAgent:(NSInteger)isAgent agentMediaIP:(NSString *)agentMediaIP agentMediaPort:(NSInteger)agentMediaPort
{
    self = [super init];
    if (self) {
        _isSending = NO;
        _isConnected = NO;
        _isConnecting = NO;
        _isReconnecting = NO;
        
        _hasSendFirstVideoFrame = NO;
        _hasSendFirstAudioFrame = NO;

        _rtp = [[Rtp alloc] initWithConfigWithRoomId:roomId userId:userId mediaId:mediaId serverIP:serverIP minPort:minPort maxPort:maxPort strToken:strToken strPcid:strPcid isAgent:isAgent agentMediaIP:agentMediaIP agentMediaPort:agentMediaPort];

        self.sortFrameBuffer = [[NSMutableArray alloc] init];
        self.rtmpUrlStrl = @"";
        
        _frameSortSemaphore = dispatch_semaphore_create(1);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtpConnectSuccess:) name:RtpConnectSuccess object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtpReportUploadInfo:) name:RtpReportUploadInfo object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtpReportConnInfo:) name:RtpReportConnInfo object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtpReportBwFullInfo:) name:RtpReportBwFullInfo object:nil];
    }
    return self;
}

-(void)start
{
    if (_isConnecting || _rtp == NULL) {
        return;
    }
    
    [self connectRtp];

}

-(void)stop
{
    if(_rtp != NULL){
        [_rtp stop];
        _rtp = nil;
    }
    [self clean];

}

-(void)connectRtp
{
    _isConnecting = YES;
    [_rtp start];
}

-(void)rtpConnectSuccess:(NSNotification *)noti
{
    _isConnecting = NO;
    
    NSDictionary *dic = noti.object;
    BOOL result = [dic[@"ConnectResult"] boolValue];
    if (result == YES) {
        //开始推流
        _isConnected = YES;
        _isReconnecting = NO;
        _isSending = NO;
    }
    else
    {
        
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectResult:)]) {
        [self.delegate connectResult:result];
    }
    
}

-(void)rtpReportUploadInfo:(NSNotification *)noti
{
    NSString *reportStr = noti.object[@"ReportUploadInfo"];
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtpReportUploadInfo:)]) {
        [self.delegate rtpReportUploadInfo:reportStr];
    }
}

-(void)rtpReportConnInfo:(NSNotification *)noti
{
    NSString *reportStr = noti.object[@"ReportConnInfo"];
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtpReportConnInfo:)]) {
        [self.delegate rtpReportConnInfo:reportStr];
    }
}

-(void)rtpReportBwFullInfo:(NSNotification *)noti
{
    NSString *reportStr = noti.object[@"ReportBwFullInfo"];
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtpReportBwFullInfo:)]) {
        [self.delegate rtpReportBwFullInfo:reportStr];
    }
}


- (void)clean{
    _isConnecting = NO;
    _isReconnecting = NO;
    _isSending = NO;
    _isConnected = NO;
    _hasSendFirstVideoFrame = NO;
    _hasSendFirstAudioFrame = NO;
    
    dispatch_semaphore_wait(_frameSortSemaphore, DISPATCH_TIME_FOREVER);
    [self.frameBuffer removeAllObjects];
    [self.sortFrameBuffer removeAllObjects];
    dispatch_semaphore_signal(_frameSortSemaphore);
    
}

-(void)sendFrame
{
    if(!_isSending && self.frameBuffer.count > 0){

        if(!_isConnected ||  _isReconnecting || _isConnecting || !_rtp) return;
        
         _isSending = YES;
        // 调用发送接口
        VVEncodeFrame *frame;
        dispatch_semaphore_wait(_frameSortSemaphore, DISPATCH_TIME_FOREVER);
        frame = [self.frameBuffer firstObject];
        [self.frameBuffer removeObjectAtIndex:0];
        dispatch_semaphore_signal(_frameSortSemaphore);

        if([frame isKindOfClass:[VVVideoEncodeFrame class]]){
            [self sendVideo:(VVVideoEncodeFrame*)frame];
        }else{
            [self sendAudio:(VVAudioEncodeFrame*)frame];
        }
    }
}

#pragma mark -- Rtmp Send

- (void)sendVideo:(VVVideoEncodeFrame*)frame{
    if(!frame || !frame.encodeData || frame.encodeData.length < 11) {_isSending = NO; return; }
    
    BOOL sendOk = NO;
    
    if (frame.isKeyFrame) {
        NSMutableData *data = [[NSMutableData alloc] init];
        uint8_t header[] = {0x00,0x00,0x00,0x01};
        [data appendBytes:header length:4];
        [data appendData:frame.sps];
        [data appendBytes:header length:4];
        [data appendData:frame.pps];
        [data appendData:frame.encodeData];
        
        sendOk = [_rtp putVideoData:(uint8_t *)data.bytes andLength:(uint32_t)data.length andTimeStamp:(unsigned int)frame.timeStamp andIsKeyFrame:frame.isKeyFrame];
    }
    else
    {
        sendOk = [_rtp putVideoData:(uint8_t *)frame.encodeData.bytes andLength:(uint32_t)frame.encodeData.length andTimeStamp:(unsigned int)frame.timeStamp andIsKeyFrame:frame.isKeyFrame];
    }
    
    if (sendOk) {
        _isSending = NO;
        [self sendFrame];
    }
    
    return;
}

- (void)sendAudio:(VVAudioEncodeFrame*)frame{
    if(!frame) {_isSending = NO; return; }
    
    BOOL sendOK = NO;
    sendOK = [_rtp putAudioData:(uint8_t *)frame.encodeData.bytes andLength:(uint32_t)frame.encodeData.length andTimeStamp:(unsigned int)frame.timeStamp];
    
    if (sendOK) {
        _isSending = NO;
        [self sendFrame];
    }

}

-(void)sendFrame:(VVEncodeFrame *)frame
{
    __weak typeof(self) _self = self;
    dispatch_async(self.socketQueue, ^{
        __strong typeof(_self) self = _self;
        if(!frame) return;
        
        dispatch_semaphore_wait(_frameSortSemaphore, DISPATCH_TIME_FOREVER);
        [self appendObject:frame];
        dispatch_semaphore_signal(_frameSortSemaphore);
        
        [self sendFrame];
    });
}

#pragma mark - frame sort
static const NSUInteger defaultSortBufferMaxCount = 10;///< 排序10个内

- (void)appendObject:(VVEncodeFrame*)frame{
    if(!frame) return;
    
    if(self.sortFrameBuffer.count < defaultSortBufferMaxCount){
        [self.sortFrameBuffer addObject:frame];
    }else{
        ///< 排序
        [self.sortFrameBuffer addObject:frame];
        NSArray *sortedSendQuery = [self.sortFrameBuffer sortedArrayUsingFunction:frameDataCompare context:NULL];
        [self.sortFrameBuffer removeAllObjects];
        [self.sortFrameBuffer addObjectsFromArray:sortedSendQuery];
        /// 丢帧
//        [self removeExpireFrame];
        /// 添加至缓冲区
        VVEncodeFrame *firstFrame = [self.sortFrameBuffer firstObject];
        if(self.sortFrameBuffer.count > 0) [self.sortFrameBuffer removeObjectAtIndex:0];
        if(firstFrame) [self.frameBuffer addObject:firstFrame];
    }
}

NSInteger frameDataCompare(id obj1, id obj2, void *context){
    VVEncodeFrame* frame1 = (VVEncodeFrame*) obj1;
    VVEncodeFrame *frame2 = (VVEncodeFrame*) obj2;
    
    if (frame1.timeStamp == frame2.timeStamp)
        return NSOrderedSame;
    else if(frame1.timeStamp > frame2.timeStamp)
        return NSOrderedDescending;
    return NSOrderedAscending;
}

#pragma mark -- Getter Setter
- (dispatch_queue_t)socketQueue{
    if(!_socketQueue){
        _socketQueue = dispatch_queue_create("VVLiveRtpSocketQueue", NULL);
    }
    return _socketQueue;
}

-(NSMutableArray *)frameBuffer
{
    if (!_frameBuffer) {
        _frameBuffer = [[NSMutableArray alloc] init];
    }
    return _frameBuffer;
}

#pragma mark - other
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_rtp != NULL){
        [_rtp stop];
        _rtp = NULL;
    }

}

@end
