//
//  DropFrameHelper.h
//  livesession
//
//  Created by hp on 16/8/30.
//  Copyright © 2016年 vvlive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DropFrameHelper : NSObject

-(void)start;
-(void)stop;

-(BOOL)isEncodeFrame;
-(void)setFrameRate:(NSInteger)frameRate;

-(id)initWithFrameRate:(NSInteger)fps useTimerTask:(BOOL)useTimerTask;
@end


@interface Frame : NSObject

@property (nonatomic, assign) NSInteger frameId;
@property (nonatomic, assign) long arriveTime;
@property (nonatomic, assign) long timeDif;

-(id)initWithFrameId:(NSInteger)frameId arriveTime:(long)arriveTime timeDif:(long)timeDif;

@end
