//
//  PlayerController.m
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/17/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import "PlayerController.h"

@implementation PlayerController

+ (void)setupAudioFormat:(AQPlayState *) playState {
	playState->mDataFormat.mFormatID = kAudioFormatLinearPCM;
	playState->mDataFormat.mSampleRate = RATE;
	playState->mDataFormat.mBitsPerChannel = 16;
	playState->mDataFormat.mChannelsPerFrame = 1;
	playState->mDataFormat.mFramesPerPacket = 1;
	playState->mDataFormat.mBytesPerFrame = playState->mDataFormat.mBytesPerPacket = playState->mDataFormat.mChannelsPerFrame * sizeof(SInt16);
	playState->mDataFormat.mReserved = 0;
	playState->mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsNonInterleaved | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked ;//| kLinearPCMFormatFlagIsBigEndian;
}

+ (void)deriveBufferSize:(Float64)seconds forState:(AQPlayState *) state {
	static const int maxBufferSize = 0x50000;
	int maxPacketSize = state->mDataFormat.mBytesPerPacket;
	if (maxPacketSize == 0) {
		UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
		AudioQueueGetProperty(state->mQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
	}
	Float64 numBytesForTime = round(state->mDataFormat.mSampleRate * 4 * 1);
	state->bufferByteSize = (UInt32) MIN(numBytesForTime, maxBufferSize);
}

+ (AudioQueueOutputCallback) callBack {
	return HandleOutputBuffer;
}

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

+ (void)encodeMessage:(NSString *)message forState:(AQPlayState *) state {
	const char * str = [message cStringUsingEncoding:NSASCIIStringEncoding];
	UInt8 encodedLength = message.length * 12 + BARKER_LEN + 1;
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

	state->messageLength = encodedLength * SAMPLE_PER_BIT;
	state->message = bpsk;
}

@end
