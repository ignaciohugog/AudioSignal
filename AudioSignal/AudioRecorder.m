//
//  AudioRecorder.m
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import "AudioRecorder.h"

@implementation AudioRecorder

- (void)startRecording {
	[RecordController setupAudioFormat:&_recordState];
	_recordState.mCurrentPacket = 0;
	[RecordController initRecorder];
	AudioQueueNewInput(&_recordState.mDataFormat, [RecordController callBack], &_recordState, NULL, NULL, 0, &_recordState.mQueue);

	[RecordController deriveBufferSize:1.0f forState:&_recordState];

	for (int i = 0; i < kNumberBuffers; i++) {
		AudioQueueAllocateBuffer(_recordState.mQueue, _recordState.bufferByteSize, &_recordState.mBuffers[i]);
		AudioQueueEnqueueBuffer(_recordState.mQueue, _recordState.mBuffers[i], 0, NULL);
	}
	_recordState.mIsRunning = YES;
	AudioQueueStart(_recordState.mQueue, NULL);
}

- (void)stopRecording {
    if (_recordState.mIsRunning) {
				AudioQueueStop(_recordState.mQueue, true);
        _recordState.mIsRunning = false;
    }
}

@end
