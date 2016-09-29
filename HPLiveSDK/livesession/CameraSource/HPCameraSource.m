//
//  HPCameraSource.m
//  HPLiveSDKDemo
//
//  Created by hp on 16/9/26.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import "HPCameraSource.h"
#import "LFGPUImageBeautyFilter.h"

@interface HPCameraSource() <GPUImageVideoCameraDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *cameraView;

@property (nonatomic, strong) GPUImageCropFilter *cropFilter;
@property (nonatomic, strong) LFGPUImageBeautyFilter *beautifulFilter;

@end


@implementation HPCameraSource

-(id)init
{
    self = [super init];
    if (self) {
        
        [self configVideoCamera];
    }
    return self;
}

-(void)configVideoCamera
{
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.frameRate = 25;
    
    self.beautifulFilter = [[LFGPUImageBeautyFilter alloc] init];
    
    __weak HPCameraSource *_w_self = self;
    [_beautifulFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        if (_w_self.delegate && [_w_self.delegate respondsToSelector:@selector(videoEncodeWithImageBuffer:)]) {
            [_w_self.delegate videoEncodeWithImageBuffer:pixelBuffer];
        }
    }];
    
    _cameraView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [_cameraView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [_cameraView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_cameraView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    
    [_videoCamera addTarget:_beautifulFilter];
    [_beautifulFilter addTarget:_cameraView];
    
    if(_videoCamera.cameraPosition == AVCaptureDevicePositionFront) [_cameraView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    else [_cameraView setInputRotation:kGPUImageNoRotation atIndex:0];
    
}


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
