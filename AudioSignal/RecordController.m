//
//  RecordController.m
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/18/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import "RecordController.h"

@implementation RecordController

+ (AudioQueueInputCallback) callBack {
	return HandleInputBuffer;
}

+ (void) initRecorder {
	fillVector();
}

+ (void)setupAudioFormat:(AQRecordState *)recordState {
	recordState->mDataFormat.mFormatID = kAudioFormatLinearPCM;
	recordState->mDataFormat.mSampleRate = 44100.0f;
	recordState->mDataFormat.mBitsPerChannel = 16;
	recordState->mDataFormat.mChannelsPerFrame = 1;
	recordState->mDataFormat.mFramesPerPacket = 1;
	recordState->mDataFormat.mBytesPerFrame = recordState->mDataFormat.mBytesPerPacket = recordState->mDataFormat.mChannelsPerFrame * sizeof(SInt16);
	recordState->mDataFormat.mReserved = 0;
	recordState->mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsNonInterleaved | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked ;//| kLinearPCMFormatFlagIsBigEndian;
}
+ (void)deriveBufferSize:(Float64)seconds forState:(AQRecordState *)state {
	static const int maxBufferSize = 0x50000;
	int maxPacketSize = state->mDataFormat.mBytesPerPacket;
	if (maxPacketSize == 0) {
		UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
		AudioQueueGetProperty(state->mQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
	}
	Float64 numBytesForTime = round(state->mDataFormat.mSampleRate * maxPacketSize * seconds);
	state->bufferByteSize = (UInt32) MIN(numBytesForTime, maxBufferSize);
}

void fillVector() {
	long bufSize = RATE;
	fBuffer = (float *)calloc(bufSize, sizeof(float));
	integral = (float *)calloc(bufSize/SAMPLE_PER_BIT, sizeof(float));
	corr = (float *)calloc(bufSize + BARKER_LEN*SAMPLE_PER_BIT, sizeof(float));
	barker = (float *)calloc(BARKER_LEN*SAMPLE_PER_BIT, sizeof(float));

	for (int i = 0; i < BARKER_LEN; i++) {
		vDSP_vfill(recorderbarkerbin+i, barker+i*SAMPLE_PER_BIT, 1, SAMPLE_PER_BIT);
	}
}

void HandleInputBuffer(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp * inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription * inPacketDesc) {
	AQRecordState * pRecordState = (AQRecordState *)inUserData;
	if (inNumPackets == 0 && pRecordState->mDataFormat.mBytesPerPacket != 0) {
		inNumPackets = inBuffer->mAudioDataByteSize / pRecordState->mDataFormat.mBytesPerPacket;
	}
	if ( ! pRecordState->mIsRunning) {
		return;
	}

	long sampleStart = pRecordState->mCurrentPacket;
	long sampleEnd = pRecordState->mCurrentPacket + inBuffer->mAudioDataByteSize / pRecordState->mDataFormat.mBytesPerPacket - 1;
	printf("buffer received : %1.6f from %1.6f (#%07ld) to %1.6f (#%07ld)\n", (sampleEnd - sampleStart + 1)/44100.0, sampleStart/44100.0, sampleStart, sampleEnd/44100.0, sampleEnd);

		// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	short * samples = (short *)inBuffer->mAudioData;
	long nsamples = sampleEnd - sampleStart + 1;
		// Convert to float
	for (long i = 0; i < nsamples; i++) {
		fBuffer[i] = samples[i] / (float)SHRT_MAX;
	}

		// BPF
	vDSP_desamp(fBuffer, 1, bpf, fBuffer, nsamples, SAMPLE_PER_BIT+1);

		// Carrier present ?
	float m = 1.0f, max = 0.0f, mean = 0.0f;
	vDSP_meamgv(fBuffer, 1, &mean, nsamples);
	printf("mean %1.9f\n", mean);

	if (mean > 10e-5) {

		max = mean;
		vDSP_maxmgv(fBuffer, 1, &max, nsamples);
		printf("max  %1.9f\n", max);
		printf("max/mean %1.9f\n", max/mean);


			// Delay Multiply
		vDSP_vmul(fBuffer, 1, fBuffer+SAMPLE_PER_BIT, 1, fBuffer, 1, nsamples-SAMPLE_PER_BIT);

			// LPF
		vDSP_desamp(fBuffer, 1, lpf, fBuffer, nsamples, SAMPLE_PER_BIT+1);

			// Time sync
		m = 1/max;
		vDSP_vsmul(barker, 1, &m, barker, 1, BARKER_LEN*SAMPLE_PER_BIT);


		vDSP_conv(fBuffer, 1, barker, 1, corr, 1, nsamples-FILTERS_DELAY, BARKER_LEN*SAMPLE_PER_BIT);


		float cc = -1.0f;
		unsigned long cci = 0;
		vDSP_vsmul(corr, 1, &cc, corr, 1, nsamples-FILTERS_DELAY);
		vDSP_maxv(corr, 1, &cc, nsamples-FILTERS_DELAY);
		cc *= CORR_MAX_COEFF;
		vDSP_vthrsc(corr, 1, &cc, &cc, corr, 1, nsamples-FILTERS_DELAY);
		vDSP_maxvi(corr, 1, &cc, &cci, nsamples-FILTERS_DELAY);
		printf("corr %1.9f\n", cc);
		printf("idx  %lu\n", cci);

		long j = -1;
		for (long i = 0; i < nsamples; i++) {
			if (corr[i] > 0) {
				if (j != i-1) {
					printf("Found frame starting at index %ld\n", i);
				}
				j = i;
			}
		}

			// Integration
		for (long i = 0; i < nsamples/SAMPLE_PER_BIT; i++) {
			if(cci+i*SAMPLE_PER_BIT < nsamples) {
				vDSP_sve(fBuffer+cci+i*SAMPLE_PER_BIT, 1, integral+i, SAMPLE_PER_BIT);
			}
		}

		int i = 13;
		char ch;
		short p;
		while (integral[i]<0 && integral[i+10]<0 && integral[i+11]<0) {
			ch = 0;
			for (int j = i+1; j < i+9; j++) {
				ch |= (integral[j]>0) << (8-j+i);
			}
			p = recorderParityTable256[ch];
			printf("%c", ch);
			strbuf[(i-13)/12] = ch;
			i += 12;
		}
		printf("\n%d characters decoded\n", (i-13)/12);
		strbuf[(i-13)/12] = '\0';
	} else {
		strbuf[0] = '(';
		strbuf[1] = 'N';
		strbuf[2] = 'o';
		strbuf[3] = ' ';
		strbuf[4] = 's';
		strbuf[5] = 'i';
		strbuf[6] = 'g';
		strbuf[7] = 'n';
		strbuf[8] = 'a';
		strbuf[9] = 'l';
		strbuf[10] = ')';
		strbuf[11] = '\0';
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithCString:strbuf encoding:NSASCIIStringEncoding] forKey:@"text"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"incoming" object:nil userInfo:userInfo];
	});



		// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	pRecordState->mCurrentPacket += inNumPackets;

	AudioQueueEnqueueBuffer(pRecordState->mQueue, inBuffer, 0, NULL);

	if (pRecordState->mIsRunning) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"stop" object:nil];
	}
}

@end
