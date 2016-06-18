//
//  RecordController.h
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/18/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header.h"

@interface RecordController : NSObject

+ (AudioQueueInputCallback)callBack;
+ (void)initRecorder;
+ (void)setupAudioFormat:(AQRecordState *)recordState;
+ (void)deriveBufferSize:(Float64)seconds forState:(AQRecordState *) state;

@end
