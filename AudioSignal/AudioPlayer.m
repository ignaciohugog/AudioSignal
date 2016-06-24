//
//  AudioPlayer.m
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import "AudioPlayer.h"

@implementation AudioPlayer

- (void) stopPlaying {
	if (_playState.mIsRunning) {
		AudioQueueStop(_playState.mQueue, true);
		_playState.mIsRunning = false;
	}
}

- (void)playMessage:(NSString *)message {
		// setup state
	_playState.mIsRunning = YES;
	_playState.mCurrentPacket = 0;
	[PlayerController setupAudioFormat:&_playState];
	[PlayerController encodeMessage:message forState:&_playState];
	[PlayerController deriveBufferSize:1.0f forState:&_playState];

		// fill outputs buffers for playing
	AudioQueueNewOutput(&_playState.mDataFormat, [PlayerController callBack], &_playState, NULL, NULL, 0, &_playState.mQueue);
	for (int i = 0; i < kNumberBuffers; i++) {
		AudioQueueAllocateBuffer(_playState.mQueue, _playState.bufferByteSize, &_playState.mBuffers[i]);
		[PlayerController callBack](&_playState, _playState.mQueue, _playState.mBuffers[i]);
	}
		// start playing
	AudioQueueStart(_playState.mQueue, NULL);
}

@end
