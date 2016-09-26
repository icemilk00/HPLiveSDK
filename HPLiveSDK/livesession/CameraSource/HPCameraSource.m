//
//  HPCameraSource.m
//  HPLiveSDKDemo
//
//  Created by hp on 16/9/26.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import "HPCameraSource.h"

@interface HPCameraSource() <GPUImageVideoCameraDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;


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
    _videoCamera.delegate = self;
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.frameRate = 25;
    
    GPUImageHighlightShadowFilter *customFilter = [[GPUImageHighlightShadowFilter alloc] init];
    _cameraView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [_cameraView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [_cameraView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_cameraView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    
    [_videoCamera addTarget:customFilter];
    [customFilter addTarget:_cameraView];
    
    if(_videoCamera.cameraPosition == AVCaptureDevicePositionFront) [_cameraView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    else [_cameraView setInputRotation:kGPUImageNoRotation atIndex:0];
    
    [_videoCamera addAudioInputsAndOutputs];
    
    [_videoCamera startCameraCapture];
    
    _cameraShowView = _cameraView;
    
}

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer andType:(GPUImageMediaType)mediaType
{
    if (mediaType == MediaTypeAudio) {
//        [_session audioEncodeWithSampBuffer:sampleBuffer];
    }
    else if (mediaType == MediaTypeVideo)
    {
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        [self.delegate videoEncodeWithImageBuffer:imageBuffer timeStamp:0];
    }
}
@end
