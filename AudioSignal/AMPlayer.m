//
//  ViewController.swift
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import "AMPlayer.h"
#import "Header.h"

void HandleOutputBuffer(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
		// get the current state
	AQPlayState * playState = (AQPlayState *)inUserData;

		//fast return
	if (!playState->mIsRunning) {return;}

		//  fill output buffer the already encoding message
	UInt32 packets = inBuffer->mAudioDataBytesCapacity/playState->mDataFormat.mBytesPerPacket;
	SInt16 *audioData = (SInt16 *)inBuffer->mAudioData;
	for(long i = playState->mCurrentPacket; i < playState->mCurrentPacket + packets; i++) {
		short encoding =  playState->message[i % playState->messageLength];
		audioData[i-playState->mCurrentPacket] = (SInt16) (sin(2 * M_PI * FRQ * i / RATE) * SHRT_MAX * encoding);
	}

		// enqueue buffer for become playeable and storage state
	inBuffer->mAudioDataByteSize = packets * 2;
	AudioQueueEnqueueBuffer(playState->mQueue, inBuffer, 0, NULL);
	playState->mCurrentPacket += packets;
}


@interface AMPlayer (Private)
- (void)setupAudioFormat;
- (void)deriveBufferSize:(Float64)seconds;
- (void)encodeMessage:(NSString *)message;
@end

@implementation AMPlayer
- (void)dealloc {
    AudioQueueDispose(_playState.mQueue, true);
}

- (void)playMessage:(NSString *)msg {
    if (_playState.mIsRunning) {
        AudioQueueStop(_playState.mQueue, true);
        _playState.mIsRunning = false;

    } else {
			[self play:msg];
    }
}

- (void)play:(NSString *)message {

	[self setupAudioFormat];
	_playState.mCurrentPacket = 0;
	[self encodeMessage:message];
	[self deriveBufferSize:1.0f];
	AudioQueueNewOutput(&_playState.mDataFormat, HandleOutputBuffer, &_playState, NULL, NULL, 0, &_playState.mQueue);
	_playState.mIsRunning = YES;

	for (int i = 0; i < kNumberBuffers; i++) {
		AudioQueueAllocateBuffer(_playState.mQueue, _playState.bufferByteSize, &_playState.mBuffers[i]);
		HandleOutputBuffer(&_playState, _playState.mQueue, _playState.mBuffers[i]);
	}

	AudioQueueStart(_playState.mQueue, NULL);
}

@end

@implementation AMPlayer (Private)
- (void)setupAudioFormat {
    _playState.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    _playState.mDataFormat.mSampleRate = 44100.0f;
    _playState.mDataFormat.mBitsPerChannel = 16;
    _playState.mDataFormat.mChannelsPerFrame = 1;
    _playState.mDataFormat.mFramesPerPacket = 1;
    _playState.mDataFormat.mBytesPerFrame = _playState.mDataFormat.mBytesPerPacket = _playState.mDataFormat.mChannelsPerFrame * sizeof(SInt16);
    _playState.mDataFormat.mReserved = 0;
    _playState.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsNonInterleaved | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked ;//| kLinearPCMFormatFlagIsBigEndian;
}

- (void)deriveBufferSize:(Float64)seconds {
    static const int maxBufferSize = 0x50000;

    int maxPacketSize = _playState.mDataFormat.mBytesPerPacket;

    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(_playState.mQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }

    Float64 numBytesForTime = round(_playState.mDataFormat.mSampleRate * 4 * 1);
    _playState.bufferByteSize = (UInt32) MIN(numBytesForTime, maxBufferSize);
}

- (void)encodeMessage:(NSString *)message {
    const char * str = [message cStringUsingEncoding:NSASCIIStringEncoding];
    UInt32 length = message.length;
    UInt32 encodedLength = length * 12 + BARKER_LEN + 1;
    unsigned char * encodedMessage = (unsigned char *)calloc(encodedLength, sizeof(unsigned char));
    char * bpsk = (char *)calloc(encodedLength * BIT_RATE, sizeof(char));

    encodedMessage[0] = 1;
    for (int i = 1; i < BARKER_LEN+1; i++) {
        encodedMessage[i] = 1&( ~(playerBarkerbin[i-1] ^ encodedMessage[i-1]));
    }
    for (int i = BARKER_LEN+1; i < encodedLength; i++) {
        switch ((i-BARKER_LEN-1)%12) {
            case 0:
            case 10:
            case 11:
                encodedMessage[i] = 1& ~(0 ^ encodedMessage[i-1]);
                break;
            case 9:
                encodedMessage[i] = 1& ~(playerParityTable[str[(i-BARKER_LEN-1)/12]] ^ encodedMessage[i-1]);
                break;
            default:
                encodedMessage[i] = 1& ~((((unsigned char)str[(i-BARKER_LEN-1)/12] >> (8-((i-BARKER_LEN-1)%12)) & 0x01)) ^ encodedMessage[i-1]);
                break;
        }
    }



		//baseband
    for (int i = 0; i < encodedLength; i++) {
        for (int j = 0; j < SAMPLE_PER_BIT; j++) {
            bpsk[i*SAMPLE_PER_BIT+j] = 2* encodedMessage[i] - 1;
        }
    }


    _playState.messageLength = encodedLength * SAMPLE_PER_BIT;
    _playState.message = bpsk;
}
@end