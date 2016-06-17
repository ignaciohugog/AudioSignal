//
//  ViewController.swift
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//
//INFO: https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioQueueProgrammingGuide/AQPlayback/PlayingAudio.html

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define kNumberBuffers 3

typedef struct {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    SInt64 mCurrentPacket;
    UInt32 mNumPacketsToRead;
    UInt32 bufferByteSize;
    bool mIsRunning;
    const char * message;
    UInt32 messageLength;
    float mTheta;
} AQPlayState;

@interface AMPlayer : NSObject
@property (nonatomic, assign) AQPlayState playState;
- (void) playMessage:(NSString *)msg;
@end
