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

-(void)videoEncodeWithImageBuffer:(CVImageBufferRef)imageBuffer;

@end

@interface HPCameraSource : NSObject

@property (nonatomic, assign) id <HPCameraSourceDelegate> delegate;

- (void)startVideoCamera;
- (void)stopVideoCamera;

-(void)setupOnView:(UIView *)showView;
@end
