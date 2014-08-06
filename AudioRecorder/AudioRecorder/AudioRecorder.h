//
//  AudioRecorder.h
//  AudioRecorder
//
//  Created by lei xue on 14-8-6.
//  Copyright (c) 2014年 xl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioRecorder : NSObject
@property(strong, nonatomic) NSURL *audioFileUrl;
@property(copy, nonatomic) void(^onRecordSuccess)(BOOL isCanceled);
@property(assign, nonatomic) void(^onRecordFailed)();

-(BOOL) refreshRecorder;
-(BOOL) startRecord;//must call refreshRecorder before startRecord.
-(void) stopRecordWithCompletionBlock:(void (^)())completion;
-(void) cancelRecord;
-(CGFloat)duration;
@end
