//
//  AudioButton.m
//  AudioButton
//
//  Created by lei xue on 14-8-4.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import "AudioButton.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioSessionConfig.h"

@interface AudioButton()<AVAudioPlayerDelegate, AudioSessionConfigDelegate>
@property(strong, nonatomic) AVAudioPlayer *player;
@property(strong, nonatomic) ProgressLayers *progressLayers;
@property(assign, nonatomic) AudioButtonState playState;
@property(strong, nonatomic) UIColor *backgroundColor;//backgroundColor and backgroundCornRadius are used to draw background rectangle in drawRect.
@property(assign, nonatomic) CGFloat backgroundCornRadius;
@property(strong, nonatomic) UIColor *buttonColor;
@property(assign, nonatomic) CGRect eclipseRect;
@property(assign, nonatomic) CGRect stopRect;
@property(assign, nonatomic) CGPoint topPoint;
@property(assign, nonatomic) CGPoint rightPoint;
@property(assign, nonatomic) CGPoint bottomPoint;

@end

@implementation AudioButton
@synthesize audioUrl = _audioUrl;
@synthesize player;
@synthesize progressLayers;
@synthesize playState;
@synthesize backgroundColor;
@synthesize backgroundCornRadius;
@synthesize buttonColor;
@synthesize eclipseRect;
@synthesize stopRect;
@synthesize topPoint;
@synthesize rightPoint;
@synthesize bottomPoint;

-(void)dealloc{
    if (player) {
        [player stop];
        player = nil;
    }
    [[AudioSessionConfig instance] unregisterAudioSessionNotificationFor:self];
}

-(void)setupWithFrame:(CGRect)frame isRound:(BOOL)isRound backgroundColor:(UIColor *)aBackgroundColor audioPath:(NSURL *)anAudioUrl{
    self.frame = frame;
    self.backgroundColor = aBackgroundColor;
    self.audioUrl = anAudioUrl;
    
    playState = AudioButtonStateIdle;
    
    progressLayers = [[ProgressLayers alloc] initWithView:self backColor:[UIColor colorWithRed:236.0 / 255.0 green:236.0 / 255.0 blue:236.0 / 255.0 alpha:1.0] progressColor:[UIColor colorWithRed:82.0 / 255.0 green:135.0 / 255.0 blue:237.0 / 255.0 alpha:1.0] lineWidth:1.5f progressShape:isRound ? ProgressLayersShapeCircle : ProgressLayersShapeRoundRectangle cornRadius:&backgroundCornRadius];
    progressLayers.delegate = self;
    
    [self addTarget:self action:@selector(buttonTouched) forControlEvents:UIControlEventTouchUpInside];
    
    //prepare parameters for drawRect CGContext.
    buttonColor = [UIColor colorWithRed:0 green:0.4784 blue:1 alpha:1];
    
    const CGFloat diameter = fmin(frame.size.height, frame.size.width) * 0.618;
    eclipseRect = CGRectMake((frame.size.width - diameter) / 2, (frame.size.height - diameter) / 2, diameter, diameter);
    
    const CGFloat side = diameter * 0.618;
    const CGFloat leftX = eclipseRect.origin.x + (diameter - 0.866 * side) * 0.667;
    const CGFloat topY = eclipseRect.origin.y + (diameter - side) / 2;
    const CGFloat bottomY = eclipseRect.origin.y + (diameter + side) / 2;
    const CGFloat rightX = leftX + 0.866 * side;
    const CGFloat middleY = eclipseRect.origin.y + diameter / 2;
    topPoint = CGPointMake(leftX, topY);
    rightPoint = CGPointMake(rightX, middleY);
    bottomPoint = CGPointMake(leftX, bottomY);
    
    stopRect = CGRectMake(eclipseRect.origin.x + diameter / 4, eclipseRect.origin.y + diameter / 4, diameter / 2, diameter / 2);
    
    //configure audio session, register notification for handleRouteChange.
    [[AudioSessionConfig instance] registerAudioSessionNotificationFor:self];
}

-(void)drawRect:(CGRect)rect{
    [backgroundColor setFill];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:backgroundCornRadius];
    [path fill];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, buttonColor.CGColor);
    CGContextSetFillColorWithColor(ctx, buttonColor.CGColor);
    CGContextSetLineWidth(ctx, 1);
    
    CGContextStrokeEllipseInRect(ctx, eclipseRect);
    
    if(playState == AudioButtonStateIdle){
        CGContextMoveToPoint(ctx, topPoint.x, topPoint.y);
        CGContextAddLineToPoint(ctx, rightPoint.x, rightPoint.y);
        CGContextAddLineToPoint(ctx, bottomPoint.x, bottomPoint.y);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
    }
    else// if (playState == AudioButtonStateLoading || playState == AudioButtonStatePlaying)
    {
        CGContextFillRect(ctx, stopRect);
    }
}

#pragma mark - ProgressLayersDelegate
-(CGFloat)currentProgress{
    if (player != nil && player.currentTime <= player.duration) {
        return (CGFloat)player.currentTime / player.duration;
    } else {
        return 0.0f;
    }
}

-(void)setAudioUrl:(NSURL *)audioUrl{
    _audioUrl = audioUrl;
    
    if (player != nil) {
        if (player.playing) {
            [self stop];
        }
        player = nil;
    }
    
    if (audioUrl == nil) {
        return;
    }
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioUrl error:nil];
    if (player != nil) {
        player.numberOfLoops = 0;
        player.volume = 1.0f;
        player.delegate = self;
        [player prepareToPlay];
    }
}

-(void)buttonTouched{
    if (player == nil) {
        return;
    }
    
    switch (playState) {
        case AudioButtonStateIdle:{
            //播放声音
            [self play];
            break;
        }
        case AudioButtonStatePlaying:{
            //停止播放声音
            [self stop];
        }
        case AudioButtonStateLoading:
        default:
            break;
    }
}

-(BOOL)play{
    if ([player play]) {
        [progressLayers play];
        playState = AudioButtonStatePlaying;
        [self setNeedsDisplay];
        return YES;
    }
    return NO;
}
-(void)stop{
    [player stop];
    [player setCurrentTime:0.0f];
    [progressLayers stop];
    playState = AudioButtonStateIdle;
    [self setNeedsDisplay];
}

#pragma mark - AudioSessionConfigDelegate, AVAudioSession notification handlers
- (void)handleRouteChange:(NSNotification *)notification
{
    /*MyNSLogToTest(@"模拟器不能模拟测试：
     1：调用中断
     2：更改静音开关的设置
     3：模拟屏幕锁定，返回首页
     4：模拟插上或拔下耳机
     5：Query audio route information or test audio session category behavior
     6. 来电、接听、挂断。");
     */
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Previous route:%@", routeDescription);
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable://e.g. headphones have been plugged in
            NSLog(@"AuidoButton routeChange: NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable://e.g. headphones have been unplugged
            [self stop];
            NSLog(@"AuidoButton routeChange: OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"AuidoButton routeChange: CategoryChange to %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"AuidoButton routeChange: Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"AuidoButton routeChange: WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"AuidoButton routeChange: NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"AuidoButton routeChange: ReasonUnknown");
    }
}

#pragma mark AVAudioPlayer delegate methods
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)p successfully:(BOOL)flag
{
	if (flag == NO)
		NSLog(@"AudioButton Playback finished unsuccessfully");
    
    [self stop];
}

- (void)playerDecodeErrorDidOccur:(AVAudioPlayer *)p error:(NSError *)error
{
	NSLog(@"AudioButton decode error: %@", error);
}

// we will only get these notifications if playback was interrupted
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p
{
	NSLog(@"AudioButton Interruption begin.");
    [self stop];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags{
    NSLog(@"AudioButton Interruption ended.");
}

@end