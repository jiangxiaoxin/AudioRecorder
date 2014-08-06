//
//  AudioSessionConfig.m
//  AudioButton
//
//  Created by lei xue on 14-8-6.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import "AudioSessionConfig.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioSessionConfig
@synthesize isConfigured;

+(id)instance{
    static AudioSessionConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AudioSessionConfig alloc] init];
        [instance configAudioSession];
        
        //configure notification when media service were reset.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configAudioSession) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    });
    return instance;
}

-(void)registerAudioSessionNotificationFor:(id<AudioSessionConfigDelegate>)delegate{
    if ([delegate respondsToSelector:@selector(handleRouteChange:)]) {
        //configure notification when audio route change
        [[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    }
}

-(void)unregisterAudioSessionNotificationFor:(id<AudioSessionConfigDelegate>)delegate{
    [[NSNotificationCenter defaultCenter] removeObserver:delegate name:AVAudioSessionRouteChangeNotification object:nil];
}

-(void)configAudioSession{
    isConfigured = YES;
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: &error];
    if (error){
        NSLog(@"Error: AVAudioSession set category: %@", error.description);
        isConfigured = NO;
    }
    
    error = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error){
        NSLog(@"Error: AVAudioSession setActive: %@", error.description);
        isConfigured = NO;
    }
}

@end
