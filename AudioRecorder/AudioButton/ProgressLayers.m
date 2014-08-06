//
//  ProgressLayers.m
//  AudioButton
//
//  Created by lei xue on 14-8-4.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import "ProgressLayers.h"

@interface ProgressLayers ()
@property (strong, nonatomic) UIColor *backColor;
@property (strong, nonatomic) UIColor *progressColor;
@property (assign, nonatomic) CGFloat lineWidth;

@property (strong, nonatomic) CADisplayLink *displayLink;//show play progress animation
@property (strong, nonatomic) CAShapeLayer *progressLayer;
@property (strong, nonatomic) CAShapeLayer *backgroundLayer;
@property (nonatomic) CAShapeLayer *loadingLayer;

@end

@implementation ProgressLayers
@synthesize backColor;
@synthesize progressColor;
@synthesize lineWidth;
@synthesize displayLink;
@synthesize progressLayer;
@synthesize progress = _progress;
@synthesize backgroundLayer;
@synthesize loadingLayer;

-(id)initWithView:(UIView *)view backColor:(UIColor *)aBackColor progressColor:(UIColor *)aProgressColor lineWidth:(CGFloat)aLineWidth progressShape:(ProgressLayersShape)progressShape cornRadius:(CGFloat *)cornRadius{
    self = [super init];
    if (self) {
        backColor = aBackColor;
        progressColor = aProgressColor;
        lineWidth = aLineWidth;
        
        CGRect frame = view.frame;
        
        if (progressShape == ProgressLayersShapeCircle) {
            CGPoint center = CGPointMake(CGRectGetWidth(frame) / 2, CGRectGetHeight(frame) / 2);
            const CGFloat radius = CGRectGetWidth(frame) / 2 - lineWidth / 2;
            *cornRadius = radius + lineWidth / 2;
            
            backgroundLayer = [self createRingLayerWithCenter:center radius:radius lineWidth:lineWidth color:self.backColor];
            progressLayer = [self createRingLayerWithCenter:center radius:radius lineWidth:lineWidth color:self.progressColor];
            loadingLayer = [self createRingLayerWithCenter:center radius:radius lineWidth:lineWidth color:self.progressColor];
        }
        else if(progressShape == ProgressLayersShapeRoundRectangle){
            const CGFloat tempWidth = frame.size.width - lineWidth;
            const CGFloat tempHeight = frame.size.height - lineWidth;
            //set cornerRadius to lineWidth * 2, but must less than min(width, height)/3
            CGFloat tempCornerRadius = fmin(tempWidth, tempHeight) / 3;
            if (lineWidth * 2 < tempCornerRadius) {
                tempCornerRadius = lineWidth * 2;
            }
            *cornRadius = tempCornerRadius;
            CGRect rect = CGRectMake(lineWidth / 2, lineWidth / 2, tempWidth, tempHeight);
            
            backgroundLayer = [self createRoundRectLayerWithRect:rect cornerRadius:tempCornerRadius lineWidth:lineWidth color:self.backColor];
            progressLayer = [self createRoundRectLayerWithRect:rect cornerRadius:tempCornerRadius lineWidth:lineWidth color:self.progressColor];
            loadingLayer = [self createCircleLayerIncludeRect:rect cornerRadius:tempCornerRadius lineWidth:lineWidth color:self.progressColor];
            backgroundLayer.mask = [self createRoundRectLayerWithRect:rect cornerRadius:tempCornerRadius lineWidth:lineWidth color:[UIColor blackColor]];
        }
        
        [view.layer addSublayer:backgroundLayer];
        
        progressLayer.strokeEnd = 0;
        [view.layer addSublayer:progressLayer];
        //        progressLayer.hidden = YES;
        
        loadingLayer.strokeEnd = 0.2;
        loadingLayer.hidden = YES;
        
        [backgroundLayer addSublayer:loadingLayer];
    }
    return self;
}

- (CAShapeLayer *)createRingLayerWithCenter:(CGPoint)center radius:(CGFloat)radius lineWidth:(CGFloat)aLineWidth color:(UIColor *)color {
    UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:(M_PI + M_PI_2) clockwise:YES];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.contentsScale = [[UIScreen mainScreen] scale];
    shapeLayer.frame = CGRectMake(center.x-radius - lineWidth / 2, center.y-radius - lineWidth / 2, radius*2 + lineWidth, radius*2 + lineWidth);//需要修改frame的位置，是因为传入参数center是没有考虑减去lineWidth/2计算，radius考虑了减去lineWidth/2计算
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = color.CGColor;
    shapeLayer.lineWidth = aLineWidth;
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.path = smoothedPath.CGPath;
    
    return shapeLayer;
}

- (CAShapeLayer *)createCircleLayerIncludeRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius lineWidth:(CGFloat)aLineWidth color:(UIColor *)color {
    //计算出恰好能将rect with lineWidth包括进去的同心圆
    const CGFloat smallRadius = fmin(rect.size.width, rect.size.height) / 2 - aLineWidth / 2;
    const CGFloat largeRadius = sqrtf(pow(rect.size.width / 2 + aLineWidth / 2, 2) + pow(rect.size.height / 2 + aLineWidth / 2, 2));
    const CGFloat radius = (smallRadius + largeRadius) / 2;
    const CGFloat tempLineWidth = largeRadius - smallRadius;
    
    UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2) radius:radius startAngle:-M_PI_2 endAngle:(M_PI + M_PI_2) clockwise:YES];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.contentsScale = [[UIScreen mainScreen] scale];
    shapeLayer.frame = CGRectMake(rect.origin.x - aLineWidth / 2, rect.origin.y - aLineWidth / 2, rect.size.width + aLineWidth, rect.size.height + aLineWidth);
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = color.CGColor;
    shapeLayer.lineWidth = tempLineWidth;
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.path = smoothedPath.CGPath;
    
    return shapeLayer;
}

- (CAShapeLayer *)createRoundRectLayerWithRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius lineWidth:(CGFloat)aLineWidth color:(UIColor *)color {
    UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.contentsScale = [[UIScreen mainScreen] scale];
    shapeLayer.frame = CGRectMake(rect.origin.x - aLineWidth / 2, rect.origin.y - aLineWidth / 2, rect.size.width + aLineWidth, rect.size.height + aLineWidth);
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = color.CGColor;
    shapeLayer.lineWidth = aLineWidth;
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.path = smoothedPath.CGPath;
    
    return shapeLayer;
}

- (void)setProgress:(float)aProgress{
    _progress = aProgress;
    self.progressLayer.strokeEnd = aProgress;
}

-(void)startLoading{
    //check to avoid adding animation multiple times
    if (loadingLayer.hidden) {
        self.loadingLayer.hidden = NO;
        CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];//"z"表示沿z轴旋转
        rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        rotationAnimation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
        rotationAnimation.duration = 2.0f;
        rotationAnimation.repeatCount = MAXFLOAT;
        [loadingLayer addAnimation:rotationAnimation forKey:nil];
    }
}

-(void)stopLoading{
    if (!loadingLayer.hidden) {
        loadingLayer.hidden = YES;
        [loadingLayer removeAllAnimations];
    }
}

- (void)updateProgress{
    //update progress value
    if ([self.delegate respondsToSelector:@selector(currentProgress)]) {
        self.progress = [self.delegate currentProgress];
    }
}

- (void)play{
    [self stopLoading];
    
    self.progressLayer.hidden = NO;
    
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
        self.displayLink.frameInterval = 6;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        self.displayLink.paused = NO;
    }
}

- (void)pause{
    [self stopLoading];
    self.displayLink.paused = YES;
}

- (void)stop{
    [self stopLoading];
    
    self.progressLayer.hidden = YES;
    
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    self.progress = 0;
}

@end
