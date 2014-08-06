//
//  AudioSessionConfig.h
//  AudioButton
//
//  Created by lei xue on 14-8-6.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioSessionConfigDelegate<NSObject>
@optional
- (void)handleRouteChange:(NSNotification *)notification;
@end

@interface AudioSessionConfig : NSObject
@property(assign, nonatomic) BOOL isConfigured;

+(id)instance;
-(void)registerAudioSessionNotificationFor:(id<AudioSessionConfigDelegate>)delegate;
-(void)unregisterAudioSessionNotificationFor:(id<AudioSessionConfigDelegate>)delegate;
@end
