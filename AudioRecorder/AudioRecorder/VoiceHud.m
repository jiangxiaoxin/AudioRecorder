//
//  VoiceHud.m
//  AudioRecorder
//
//  Created by lei xue on 14-8-6.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import "VoiceHud.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - <CLASS> - LCPorgressImageView

@interface LCPorgressImageView : UIImageView
@property (assign, nonatomic) float progress;
@property (assign, nonatomic) BOOL  isGrayscaleBackground;
@property (assign, nonatomic) BOOL isVertical;
@property(strong, nonatomic) UIImage *originalImage;
@property(assign, nonatomic) BOOL internalUpdating;

- (id)initWithFrame:(CGRect)frame grayscaleBackground:(BOOL)anIsGrayscaleBackground vertical:(BOOL)anIsVertical;
@end

@implementation LCPorgressImageView
@synthesize progress = _progress;
@synthesize isGrayscaleBackground;
@synthesize isVertical;
@synthesize originalImage;
@synthesize internalUpdating;

- (id)initWithFrame:(CGRect)frame grayscaleBackground:(BOOL)anIsGrayscaleBackground vertical:(BOOL)anIsVertical{
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0.f;
        isGrayscaleBackground = anIsGrayscaleBackground;
        isVertical = anIsVertical;
    }
    return self;
}

- (void)setProgress:(float)progress{
    _progress = MIN(MAX(0.f, progress), 1.f);
    if (originalImage != nil) {
        self.image = [self partialImage:originalImage percentage:_progress vertical:isVertical grayscaleRest:isGrayscaleBackground];
    }
}

//http://stackoverflow.com/questions/1298867/convert-image-to-grayscale
- (UIImage *) partialImage:(UIImage *)srcImage percentage:(float)percentage vertical:(BOOL)vertical grayscaleRest:(BOOL)grayscaleRest {
    const int ALPHA = 0;
    const int RED = 1;
    const int GREEN = 2;
    const int BLUE = 3;
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, srcImage.size.width * srcImage.scale, srcImage.size.height * srcImage.scale);
    
    int width = imageRect.size.width;
    int height = imageRect.size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [srcImage CGImage]);
    
    int x_origin = vertical ? 0 : width * percentage;
    int y_to = vertical ? height * (1.f -percentage) : height;
    
    for(int y = 0; y < y_to; y++) {
        for(int x = x_origin; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            if (grayscaleRest) {
                // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
                uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
                
                // set the pixels to gray
                rgbaPixel[RED] = gray;
                rgbaPixel[GREEN] = gray;
                rgbaPixel[BLUE] = gray;
            }
            else {
                rgbaPixel[ALPHA] = 0;
                rgbaPixel[RED] = 0;
                rgbaPixel[GREEN] = 0;
                rgbaPixel[BLUE] = 0;
            }
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image scale:srcImage.scale orientation:UIImageOrientationUp];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}
@end

#pragma mark - <CLASS> - LCVoice HUD
@interface VoiceHud()
@property(strong, nonatomic)UIImageView * talkingImageView;
@property(strong, nonatomic)LCPorgressImageView *dynamicProgress;
@end

@implementation VoiceHud
@synthesize talkingImageView;
@synthesize dynamicProgress;

- (id)init
{
    self = [super initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setMeterPercentage:0.0f];
        self.alpha = 0;
        
        [self createMainUI];
    }
    return self;
}

-(void) createMainUI{
//    const CGFloat kStatusBarHeight = 20.0f;
//    const CGFloat kScreenWidth = [UIScreen mainScreen].bounds.size.width;
//    const CGFloat kScreenHeight = [UIScreen mainScreen].bounds.size.height - kStatusBarHeight;
    const CGFloat kMicSide = 179;
    
//    UIImageView * backBlackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kStatusBarHeight, kScreenWidth, kScreenHeight)];
    UIImageView * backBlackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 230, 280)];
    backBlackImageView.image = [UIImage imageNamed:@"mic_bg_460x560.png"];
    backBlackImageView.alpha = 0.618f;
    backBlackImageView.center = self.center;
    [self addSubview:backBlackImageView];
    
    UIImageView * micNormalImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mic_normal_358x358.png"]];
    micNormalImageView.frame = CGRectMake(0, 0, kMicSide, kMicSide);
    micNormalImageView.center = self.center;
    [self addSubview:micNormalImageView];

    talkingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kMicSide, kMicSide)];
    talkingImageView.image = [UIImage imageNamed:@"mic_talk_358x358.png"];
    [self addSubview:talkingImageView];
    talkingImageView.center = self.center;
    
    dynamicProgress = [[LCPorgressImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 58.5) grayscaleBackground:noErr vertical:YES];
    dynamicProgress.originalImage = [UIImage imageNamed:@"wave70x117.png"];
    dynamicProgress.center = CGPointMake(self.center.x, self.center.y-13);
    [self addSubview:dynamicProgress];
}

#pragma mark - Custom Accessor
-(void)setMeterPercentage:(CGFloat)percent{
    dynamicProgress.progress = percent;
    if (percent <= 0.01){
        [UIView animateWithDuration:0.2 animations:^{
            talkingImageView.alpha = 0;
        }];
    }
    else{
        [UIView animateWithDuration:0.2 animations:^{
            talkingImageView.alpha = 1;
        }];
    }
}

#pragma mark - Public Function
-(void) show{
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
    }];
}

-(void) hide{
    [self removeFromSuperview];
}
@end
