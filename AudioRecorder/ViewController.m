//
//  ViewController.m
//  AudioRecorder
//
//  Created by lei xue on 14-8-6.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import "ViewController.h"
#import "AudioRecorder.h"
#import "AudioButton.h"

@interface ViewController ()
@property(strong, nonatomic) AudioButton *audioButton;
@property(strong, nonatomic) AudioRecorder *audioRecorder;
@end

@implementation ViewController
@synthesize audioButton;
@synthesize audioRecorder;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    audioButton = [AudioButton buttonWithType:UIButtonTypeCustom];
    [audioButton setupWithFrame:CGRectMake(30, 100, 50, 20) isRound:NO backgroundColor:[UIColor whiteColor] audioPath:nil];
    [self.view addSubview:audioButton];
    
    audioRecorder = [[AudioRecorder alloc] init];
    audioRecorder.audioFileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"recordvoice.caf"]];
    __weak ViewController *wself = self;
    [audioRecorder setOnRecordSuccess:^(BOOL isCanceled){
        if (isCanceled) {
            CGFloat duration = [wself.audioRecorder duration];
            NSLog(@"duration %f", duration);
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"录音结束" message:@"Canceled" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
            [alert show];
            
            wself.audioButton.audioUrl = nil;
        }
        else{
            CGFloat duration = [wself.audioRecorder duration];
            NSLog(@"duration %f", duration);
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"\nrecord finish ! \npath:%@ \nduration:%f",wself.audioRecorder.audioFileUrl.path,duration] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
            [alert show];
            
            wself.audioButton.audioUrl = wself.audioRecorder.audioFileUrl;
        }
    }];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height-100, 100, 100);
    [button setTitle:@"录制" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    // Set record start action for UIControlEventTouchDown
    [button addTarget:self action:@selector(recordStart) forControlEvents:UIControlEventTouchDown];
    // Set record end action for UIControlEventTouchUpInside
    [button addTarget:self action:@selector(recordEnd) forControlEvents:UIControlEventTouchUpInside];
    // Set record cancel action for UIControlEventTouchUpOutside
    [button addTarget:self action:@selector(recordCancel) forControlEvents:UIControlEventTouchUpOutside];
}


-(void) recordStart
{
    if ([audioRecorder refreshRecorder]) {
        [audioRecorder startRecord];
    }
}

-(void) recordEnd
{
    [audioRecorder stopRecordWithCompletionBlock:nil];
}

-(void) recordCancel
{
    [audioRecorder cancelRecord];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
