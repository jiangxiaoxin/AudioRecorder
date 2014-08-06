//
//  AudioRecorder.m
//  AudioRecorder
//
//  Created by lei xue on 14-8-6.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import "AudioRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "VoiceHud.h"
#import "AudioSessionConfig.h"

@interface AudioRecorder()<AVAudioRecorderDelegate, AudioSessionConfigDelegate>
@property(strong, nonatomic)NSDictionary *recordSetting;
@property(strong, nonatomic)AVAudioRecorder *audioRecorder;
@property(strong, nonatomic)NSTimer *meteringTimer;//timer to update meter measure appearance.
@property(strong, nonatomic)VoiceHud *voiceHud;
@property(assign, nonatomic)BOOL isCanceled;//to indicate whether record successfully by stop or cancel operation. because audioRecorderDidFinishRecording will always set successfully=YES when stop or cancel.
@end

@implementation AudioRecorder
@synthesize onRecordSuccess;
@synthesize onRecordFailed;
@synthesize audioFileUrl;
@synthesize recordSetting;
@synthesize audioRecorder;
@synthesize meteringTimer;
@synthesize voiceHud;
@synthesize isCanceled;

-(id)init{
    self = [super init];
    if (self) {
        /*60s:
         kAudioFormatMPEG4AAC, 8000 ~= 124K
         kAudioFormatMPEG4AAC, 16000 ~= 185K
         kAudioFormatAppleIMA4, 8000 ~= 252K
         */
        recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,//录音格式,kAudioFormatAppleIMA4大概是kAudioFormatMPEG4AAC的两倍大小
                         [NSNumber numberWithFloat:16000.0f], AVSampleRateKey, //录音采样率(Hz) 如：AVSampleRateKey==8000/16000/44100/96000（影响音频的质量）
                         [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                         [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,//线性采样位数8,16,24,32,默认 16
                         [NSNumber numberWithInt:1], AVNumberOfChannelsKey,//通道的数目,1 or 2.
                         [NSNumber numberWithInt:AVAudioQualityHigh], AVEncoderAudioQualityKey,//录音的质量
                         //                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,//大端还是小端 是内存的组织方式
                         //                                    [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,//采样信号是整数还是浮点数
                         nil];
        
        //configure audio session, register notification for handleRouteChange.
        [[AudioSessionConfig instance] registerAudioSessionNotificationFor:self];
    }
    return self;
}

-(void) dealloc{
    if (audioRecorder.isRecording) {
        [audioRecorder stop];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL) refreshRecorder{
    if (audioFileUrl == nil) {
        NSLog(@"Audio record error: file url is nil.");
        return NO;
    }
    
    if (audioRecorder != nil) {
        if (audioRecorder.isRecording) {
            [audioRecorder stop];
        }
        audioRecorder = nil;
    }
    
    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[audioFileUrl path]] && ![[NSFileManager defaultManager] removeItemAtPath:[audioFileUrl path] error:&error]) {
        NSLog(@"Audio record error(remove file): %@", error.description);
        return NO;
    }
    
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:audioFileUrl settings:recordSetting error:&error];
    if (error) {
        NSLog(@"Audio record error: %@", error.description);
        return NO;
    }
    audioRecorder.delegate = self;
    audioRecorder.meteringEnabled = YES;
    [audioRecorder prepareToRecord];
    return YES;
}

-(BOOL)startRecord{
    if (audioRecorder == nil) {
        return NO;
    }
    
    if ([audioRecorder recordForDuration:60]) {
        [self resetMeteringTimer];
        meteringTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];
        
        [self showVoiceHud];
        return YES;
    }
    return NO;
}

-(void)stopRecord{
    [self resetMeteringTimer];
    [self invalidateVoiceHud];
    [audioRecorder stop];
}

-(void)stopRecordWithCompletionBlock:(void (^)())completion{
    isCanceled = NO;
    
    [self stopRecord];
//    audioRecorder = nil;//MUST NOT reset to nil, otherwise the audio file is not saved.
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(),completion);
    }
}

-(void)cancelRecord{
    isCanceled = YES;
    [self stopRecord];
    audioRecorder = nil;
}

-(CGFloat)duration{
    if (audioFileUrl == nil || audioRecorder == nil) {
        return 0.0f;
    }
    
    AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:audioFileUrl options:nil];
    CMTime audioDuration = audioAsset.duration;
    return CMTimeGetSeconds(audioDuration);
}

- (void)updateMeters {
    if (voiceHud)
    {
        /*  发送updateMeters消息来刷新平均和峰值功率。
         *  此计数是以对数刻度计量的，-160表示完全安静，
         *  0表示最大输入值
         */
        if (audioRecorder.isRecording) {
            [audioRecorder updateMeters];
        }
        
        //将meters转换为更加合理的可视值。
        CGFloat level = 0.0f;                // The linear 0.0 .. 1.0 value we need.
        const CGFloat minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
        const CGFloat decibels = [audioRecorder averagePowerForChannel:0];
        
        if (decibels < minDecibels){
            level = 0.0f;
        }
        else if (decibels >= -0.01f){
            level = 1.0f;
        }
        else{
            CGFloat root = 2.0f;
            CGFloat minAmp = powf(10.0f, 0.05f * minDecibels);
            CGFloat inverseAmpRange = 1.0f / (1.0f - minAmp);
            CGFloat amp = powf(10.0f, 0.05f * decibels);
            CGFloat adjAmp = (amp - minAmp) * inverseAmpRange;
            
            level = powf(adjAmp, 1.0f / root);
        }
        [voiceHud setMeterPercentage:level];
    }
}

-(void)resetMeteringTimer
{
    if (meteringTimer) {
        [meteringTimer invalidate];
        meteringTimer = nil;
    }
}

-(void)invalidateVoiceHud{
    if (voiceHud) {
        [voiceHud hide];
        voiceHud = nil;
    }
}

-(void)showVoiceHud{
    [self invalidateVoiceHud];
    voiceHud = [[VoiceHud alloc] init];
    [voiceHud show];
}

#pragma mark AVAudioSession notification handlers
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
            NSLog(@"AudioRecorder routeChange: NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable://e.g. headphones have been unplugged
            [self stopRecordWithCompletionBlock:nil];
            NSLog(@"AudioRecorder routeChange: OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"AudioRecorder routeChange: CategoryChange to %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"AudioRecorder routeChange: Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"AudioRecorder routeChange: WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"AudioRecorder routeChange: NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"AudioRecorder routeChange: ReasonUnknown");
    }
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (flag) {
        if (onRecordSuccess) {
            onRecordSuccess(isCanceled);
        }
    }
    else{
        if (onRecordFailed) {
            onRecordFailed();
        }
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error{
    NSLog(@"AudioRecorder encode error when recording: %@", error.description);
    if (onRecordFailed) {
        onRecordFailed();
    }
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder{
    NSLog(@"AudioRecorder interrupted");
    [self stopRecordWithCompletionBlock:nil];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags{
    NSLog(@"AudioRecorder end interruption");
}
@end
