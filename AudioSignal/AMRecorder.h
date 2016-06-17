//
//  ViewController.swift
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//
//INFO: https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioQueueProgrammingGuide/AQRecord/RecordingAudio.html#//apple_ref/doc/uid/TP40005343-CH4-SW1

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include <limits.h>
#include <Accelerate/Accelerate.h>
#import "Header.h"

typedef struct {
		//id mSelf;
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    bool mIsRunning;
} AQRecordState;

@interface AMRecorder : NSObject
@property (nonatomic, assign) AQRecordState recordState;

- (void)startRecording;

@end
