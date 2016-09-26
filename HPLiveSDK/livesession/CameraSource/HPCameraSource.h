//
//  HPCameraSource.h
//  HPLiveSDKDemo
//
//  Created by hp on 16/9/26.
//  Copyright © 2016年 51vv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GPUImage.h"

@protocol HPCameraSourceDelegate <NSObject>

-(void)videoEncodeWithImageBuffer:(CVImageBufferRef)imageBuffer timeStamp:(uint64_t)time;

@end

@interface HPCameraSource : NSObject

@property (nonatomic, strong) UIView *cameraShowView;
@property (nonatomic, strong) GPUImageView *cameraView;
@property (nonatomic, assign) id <HPCameraSourceDelegate> delegate;

@end
