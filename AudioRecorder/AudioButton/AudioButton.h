//
//  AudioButton.h
//  AudioButton
//
//  Created by lei xue on 14-8-4.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressLayers.h"

typedef enum {
    AudioButtonStateIdle,
    AudioButtonStateLoading,
    AudioButtonStatePlaying,
}AudioButtonState;

@interface AudioButton : UIButton<ProgressLayersDelegate>
@property(copy, nonatomic) NSURL *audioUrl;

-(void)setupWithFrame:(CGRect)frame isRound:(BOOL)isRound backgroundColor:(UIColor *)aBackgroundColor audioPath:(NSURL *)anAudioUrl;
-(void)stop;
@end
