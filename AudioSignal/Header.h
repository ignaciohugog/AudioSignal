//
//  Header.h
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/17/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#ifndef Header_h
#define Header_h

#define RATE 44100
#define FRQ (RATE*8/18)
#define BIT_RATE (RATE/36)
#define SAMPLE_PER_BIT (RATE/BIT_RATE)
#define BARKER_LEN 13
#define CORR_MAX_COEFF 0.9
#define kNumberBuffers 3

	// Player

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

static const unsigned char playerParityTable[256] =
{
#   define P2(n) n, n^1, n^1, n
#   define P4(n) P2(n), P2(n^1), P2(n^1), P2(n)
#   define P6(n) P4(n), P4(n^1), P4(n^1), P4(n)
	P6(0), P6(1), P6(1), P6(0)
};

static unsigned char playerBarkerbin[BARKER_LEN] = {
	0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0
};

	// Recorder

static const bool recorderParityTable256[256] =
{
#   define P2(n) n, n^1, n^1, n
#   define P4(n) P2(n), P2(n^1), P2(n^1), P2(n)
#   define P6(n) P4(n), P4(n^1), P4(n^1), P4(n)
	P6(0), P6(1), P6(1), P6(0)
};

static float bpf[SAMPLE_PER_BIT+1] = {
	+0.0055491, -0.0060955, +0.0066066, -0.0061506, +0.0033972, +0.0028618,
	-0.0130922, +0.0265188, -0.0409498, +0.0530505, -0.0590496, +0.0557252,
	-0.0414030, +0.0166718, +0.0154256, -0.0498328, +0.0804827, -0.1016295,
	+0.1091734, -0.1016295, +0.0804827, -0.0498328, +0.0154256, +0.0166718,
	-0.0414030, +0.0557252, -0.0590496, +0.0530505, -0.0409498, +0.0265188,
	-0.0130922, +0.0028618, +0.0033972, -0.0061506, +0.0066066, -0.0060955,
	+0.0055491
};

static float lpf[SAMPLE_PER_BIT+1] = {
	0.0025649, 0.0029793, 0.0039200, 0.0054457, 0.0075875, 0.0103454,
	0.0136865, 0.0175452, 0.0218251, 0.0264022, 0.0311308, 0.0358496,
	0.0403893, 0.0445807, 0.0482632, 0.0512926, 0.0535482, 0.0549392,
	0.0554092, 0.0549392, 0.0535482, 0.0512926, 0.0482632, 0.0445807,
	0.0403893, 0.0358496, 0.0311308, 0.0264022, 0.0218251, 0.0175452,
	0.0136865, 0.0103454, 0.0075875, 0.0054457, 0.0039200, 0.0029793,
	0.0025649
};

static float recorderbarkerbin[BARKER_LEN] = {
	+1.0f, +1.0f, +1.0f, +1.0f, +1.0f, -1.0f, -1.0f, +1.0f, +1.0f, -1.0f, +1.0f, -1.0f, +1.0f
};

#endif /* Header_h */
