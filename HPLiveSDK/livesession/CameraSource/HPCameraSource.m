//
//  HPCameraSource.m
//  HPLiveSDKDemo
//
//  Created by hp on 16/9/26.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import "HPCameraSource.h"
#import "UIDevice+Performance.h"
#import "LFGPUImageBeautyFilter.h"

#define CURRENT_IOS_VERISON [[[UIDevice currentDevice] systemVersion] floatValue]

@interface HPCameraSource() <GPUImageVideoCameraDelegate>
{
    NSUInteger _cameraFrameRate;
    CGSize _videoOutPutSize;
}
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *cameraView;

@property (nonatomic, strong) GPUImageCropFilter *cropFilter;
@property (nonatomic, strong) LFGPUImageBeautyFilter *beautifulFilter;
@property (nonatomic, strong) GPUImageFilter *videoDataFilter;

@end


@implementation HPCameraSource

-(id)initWithFrameRate:(NSUInteger)frameRate
{
    self = [super init];
    if (self) {
        _cameraFrameRate = frameRate;
        _videoOutPutSize = CGSizeMake(360, 640);
        [self configVideoCamera];
    }
    return self;
}

-(void)configVideoCamera
{
    // 使用GPUImage，开启摄像头后，如果要响应闹钟中断，必须做如下处理。
    if (CURRENT_IOS_VERISON >= 7.0) {
        [_videoCamera.captureSession setUsesApplicationAudioSession:NO];    // 开启摄像头后，app能正常响应闹钟等中断
    }
    
    NSString *sessionPreset = AVCaptureSessionPreset1280x720;
    if ([UIDevice isLowPerformanceDvice]) {
        sessionPreset = AVCaptureSessionPreset640x480;
    }
    
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:sessionPreset cameraPosition:AVCaptureDevicePositionFront];
    //    摄像头输出方向
    //    UIInterfaceOrientationUnknown
    //    UIInterfaceOrientationPortrait            //正常方向
    //    UIInterfaceOrientationPortraitUpsideDown  //倒立方向
    //    UIInterfaceOrientationLandscapeLeft       //横屏左边
    //    UIInterfaceOrientationLandscapeRight      //横屏右边
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;  //前置摄像头是否左右反转
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;    //后置摄像头是否左右反转
    
    self.cropFilter = [[GPUImageCropFilter alloc] init];            //裁剪滤镜
    self.beautifulFilter = [[LFGPUImageBeautyFilter alloc] init];   //美颜滤镜
    self.videoDataFilter = [[GPUImageFilter alloc] init];           //输出滤镜
    
    __weak HPCameraSource *_w_self = self;
    [_videoDataFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        //NSLog(@"imageFramebuffer.size = %f, %f", imageFramebuffer.size.width, imageFramebuffer.size.height);
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        if (_w_self.delegate && [_w_self.delegate respondsToSelector:@selector(videoEncodeWithImageBuffer:)]) {
            [_w_self.delegate videoEncodeWithImageBuffer:pixelBuffer];
        }
    }];
    
    _cameraView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [_cameraView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [_cameraView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    [self configCameraSettings];
    
    [_videoCamera addTarget:_cropFilter];
    [_cropFilter addTarget:_beautifulFilter];
    [_beautifulFilter addTarget:_videoDataFilter];
    [_videoDataFilter addTarget:_cameraView];
    
    [_cropFilter forceProcessingAtSize:_videoOutPutSize];
    [_beautifulFilter forceProcessingAtSize:_videoOutPutSize];
    [_videoDataFilter forceProcessingAtSize:_videoOutPutSize];
    
}

#pragma mark - control
- (void)startVideoCamera
{
#if !TARGET_IPHONE_SIMULATOR
    [_videoCamera startCameraCapture];
#endif
}

- (void)stopVideoCamera
{
#if !TARGET_IPHONE_SIMULATOR
    [_videoCamera stopCameraCapture];
#endif
}

#pragma mark - config
-(void)configCameraSettings
{
    _videoCamera.frameRate = (int32_t)_cameraFrameRate;
    [self configCropFliter];    //设置剪裁滤镜
}

-(void)configCropFliter
{
    //vamera世纪分辨率 width x heigth
    CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(_videoCamera.inputCamera.activeFormat.formatDescription);
    NSLog(@"camera videosize: %.3dx%.3d", dim.width, dim.height);
    
    CGSize cameraSize = CGSizeMake(dim.height, dim.width);  //竖屏所以要宽高互换
    
    float cameraSizeScale = cameraSize.width/cameraSize.height;
    float outputSizeScale = _videoOutPutSize.width/_videoOutPutSize.height;
    
    float cameraCropWidth = 0.0f;
    float cameraCropHeight = 0.0f;
    if (cameraSizeScale > outputSizeScale) {
        //采集宽高比例大于输出宽高比
        cameraCropWidth = (cameraSize.width - _videoOutPutSize.width * cameraSize.height / _videoOutPutSize.height) / cameraSize.width;
    }
    else
    {
        cameraCropHeight = (cameraSize.height - _videoOutPutSize.height * cameraSize.width / _videoOutPutSize.width) / cameraSize.height;
    }
    
    CGRect cropSize = CGRectMake(cameraCropWidth / 2, cameraCropHeight / 2, 1.0 - cameraCropWidth, 1.0 - cameraCropHeight);
    [self.cropFilter setCropRegion:cropSize];
}

-(void)setCurrentCameraPosition:(AVCaptureDevicePosition)cameraPosition
{
    if ([_videoCamera cameraPosition] == cameraPosition) {
        return;
    }
    
    [self rotateCamera];
}

-(void)rotateCamera
{
    [_videoCamera rotateCamera];
    
    [self configCameraSettings];
}

- (AVCaptureDevicePosition)currentCameraPosition
{
    return [_videoCamera cameraPosition];
}

-(void)setupOnView:(UIView *)showView
{
    if(self.cameraView.superview)
    {
        [self.cameraView removeFromSuperview];
    }
    self.cameraView.frame = showView.bounds;
    [showView addSubview:self.cameraView];
}
@end
