//
//  AudioRecorder.h
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//
//INFO: https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioQueueProgrammingGuide/AQRecord/RecordingAudio.html#//apple_ref/doc/uid/TP40005343-CH4-SW1

#import "Header.h"
#import "RecordController.h"

@interface AudioRecorder : NSObject
@property (nonatomic, assign) AQRecordState recordState;

- (void)startRecording;
- (void)stopRecording;

@end
