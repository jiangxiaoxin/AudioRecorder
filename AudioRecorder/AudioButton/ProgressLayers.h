//
//  ProgressLayers.h
//  AudioButton
//
//  Created by lei xue on 14-8-4.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProgressLayersDelegate <NSObject>
-(CGFloat)currentProgress;
@end

typedef enum{
    ProgressLayersShapeCircle,
    ProgressLayersShapeRoundRectangle,
}ProgressLayersShape;

@interface ProgressLayers : NSObject
@property (assign, nonatomic) float progress;
@property (assign, nonatomic) id <ProgressLayersDelegate> delegate;

-(id)initWithView:(UIView *)view backColor:(UIColor *)aBackColor progressColor:(UIColor *)aProgressColor lineWidth:(CGFloat)aLineWidth progressShape:(ProgressLayersShape)progressShape cornRadius:(CGFloat *)cornRadius;

-(void)startLoading;
-(void)stopLoading;
- (void)play;
- (void)pause;
- (void)stop;

@end